{ inputs, ... }:

{
  self.homeModules.mcps.value =
    {
      pkgs,
      lib,
      osConfig,
      config,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
      system = pkgs.stdenv.hostPlatform.system;

      sshDir = "${config.home.homeDirectory}/.cache/dot/git-mcp";
      planDir = "${config.home.homeDirectory}/.local/share/mcp-plan";

      bwrapBase = [
        "--die-with-parent"
        "--unshare-all"
        "--ro-bind-try"
        "/nix/store"
        "/nix/store"
        "--ro-bind"
        "/usr"
        "/usr"
        "--ro-bind"
        "/bin"
        "/bin"
        "--ro-bind-try"
        "/sbin"
        "/sbin"
        "--ro-bind-try"
        "/lib"
        "/lib"
        "--ro-bind-try"
        "/lib64"
        "/lib64"
        "--ro-bind-try"
        "/etc/passwd"
        "/etc/passwd"
        "--ro-bind-try"
        "/etc/group"
        "/etc/group"
        "--ro-bind-try"
        "/etc/nsswitch.conf"
        "/etc/nsswitch.conf"
        "--ro-bind-try"
        "/etc/hosts"
        "/etc/hosts"
        "--ro-bind-try"
        "/etc/resolv.conf"
        "/etc/resolv.conf"
        "--tmpfs"
        "/tmp"
        "--proc"
        "/proc"
        "--dev"
        "/dev"
      ];

      nixMcpServer = inputs.mcp-nix.packages.${system}.mcp-nix-podman;
      gitMcpServerBwrap = inputs.haraspkgs.packages.${system}.git-mcp-server-bwrap.override {
        bwrapArgs = bwrapBase;
      };
      filesystemMcpServer = inputs.haraspkgs.packages.${system}.mcp-server-filesystem-bwrap;
      planMcpServer = inputs.mcp-plan.packages.${system}.mcp-plan;
      webMcpServer = inputs.mcp-server-web.packages.${system}.mcp-server-web;

      bwrapNvidia = [
        "--ro-bind-try"
        "/run/opengl-driver"
        "/run/opengl-driver"
        "--dev-bind-try"
        "/dev/dri"
        "/dev/dri"
        "--dev-bind-try"
        "/dev/nvidia0"
        "/dev/nvidia0"
        "--dev-bind-try"
        "/dev/nvidiactl"
        "/dev/nvidiactl"
        "--dev-bind-try"
        "/dev/nvidia-modeset"
        "/dev/nvidia-modeset"
        "--dev-bind-try"
        "/dev/nvidia-uvm"
        "/dev/nvidia-uvm"
        "--dev-bind-try"
        "/dev/nvidia-uvm-tools"
        "/dev/nvidia-uvm-tools"
      ];

      # NOTE: this replaces the default sandbox of the server, so it has to
      # keep what the default has: --new-session stops a program from pushing
      # input into the terminal the server runs in. Overlay mounts cannot nest
      # in this sandbox, so haraspkgs tools copy their generated files into
      # the tree instead
      nixSandbox = builtins.concatStringsSep " " (
        bwrapBase
        ++ [
          "--new-session"
          "--setenv"
          "HARASPKGS_MATERIALIZE"
          "1"
          "--bind"
          "@ROOT@"
          "@ROOT@"
        ]
        ++ lib.optionals hardware.cuda bwrapNvidia
      );

      # NOTE: the stdio servers are scoped to the directory the harness was
      # started in. The package adds the container sandbox to these
      # arguments, and the sandbox of the nix commands comes with the server
      nixMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-nix-mcp-server";
        text = ''
          root="$(pwd -P)"
          sandbox="${nixSandbox}"
          MCP_NIX__BWRAP_ARGS="''${sandbox//@ROOT@/$root}"
          export MCP_NIX__BWRAP_ARGS
          exec ${lib.getExe nixMcpServer} "$@"
        '';
      };

      gitMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-git-mcp-server";
        runtimeInputs = [ gitMcpServerBwrap ];
        text = ''
          GIT_BASE_DIR="$(pwd -P)"
          export GIT_BASE_DIR
          exec ${lib.getExe gitMcpServerBwrap} "$@"
        '';
      };

      filesystemMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-filesystem-mcp-server";
        runtimeInputs = [ filesystemMcpServer ];
        text = ''
          FS_BASE_DIR="$(pwd -P)"
          export FS_BASE_DIR
          exec ${lib.getExe filesystemMcpServer} "$@"
        '';
      };

      # NOTE: the plan server is not sandboxed, because it only answers tool
      # calls with what is in its own database
      #
      # NOTE: the config is passed explicitly, because otherwise the server
      # reads the config.toml of the project the harness starts it in, and
      # every task needs a source, which only the config can add. The server
      # creates the folder of the database itself
      planConfig = (pkgs.formats.toml { }).generate "mcp-plan.toml" {
        database.url = "sqlite://${planDir}/data.db";
        sources = [
          {
            id = "manual";
            title = "Manual";
            description = "Tasks added by hand, by the human or by an agent in a session.";
            type = "manual";
          }
        ];
      };

      # NOTE: the server matches subdomains of every entry
      webAllowedDomains = [
        "claude.com"
        "github.com"
        "github.io"
        "githubusercontent.com"
        "nixos.org"
        "nix.dev"
        "kernel.org"
        "developer.mozilla.org"
        "docs.rs"
        "doc.rust-lang.org"
        "rfc-editor.org"
        "arxiv.org"
        "wikipedia.org"
        "wikimedia.org"
        "index.hr"
        "arstechnica.com"
        "bleepingcomputer.com"
        "404media.co"
        "lwn.net"
        "ycombinator.com"
        "algolia.com"
        "crates.io"
        "python.org"
        "readthedocs.io"
        "man7.org"
        "stackoverflow.com"
        "stackexchange.com"
        "wearedevelopers.com"
        "workingnomads.com"
      ];

      # NOTE: nothing is writable (the page cache lives in memory), the network
      # is shared because fetching pages is the whole point, the CA bundle is
      # already visible through the store bind, and the environment is cleared
      # so no harness secrets leak into it
      webSandbox = bwrapBase ++ [
        "--share-net"
        "--clearenv"
        "--setenv"
        "HOME"
        "/tmp"
        "--setenv"
        "LANG"
        "C.UTF-8"
        "--setenv"
        "SSL_CERT_FILE"
        "${osConfig.security.pki.caBundle}"
        "--setenv"
        "MCP_WEB_ALLOW_DOMAINS"
        (builtins.concatStringsSep "," webAllowedDomains)
      ];

      webMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-web-mcp-server";
        runtimeInputs = [ pkgs.bubblewrap ];
        text = ''
          exec bwrap ${lib.escapeShellArgs webSandbox} \
            ${lib.getExe webMcpServer} "$@"
        '';
      };
    in
    lib.mkIf hardware.editor {
      programs.mcp = {
        enable = true;

        servers = {
          git = {
            command = lib.getExe gitMcpServerWrapper;
            env.GIT_SSH_DIR = sshDir;
          };

          filesystem.command = lib.getExe filesystemMcpServerWrapper;

          nix.command = lib.getExe nixMcpServerWrapper;

          web.command = lib.getExe webMcpServerWrapper;

          plan = {
            command = lib.getExe planMcpServer;
            args = [
              "--config"
              "${planConfig}"
              "run"
            ];
          };
        };
      };
    };
}
