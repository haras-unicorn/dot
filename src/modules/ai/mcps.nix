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
      memoryDir = "${config.home.homeDirectory}/.local/share/dot/memory";
      memoryPort = 8765;
      # NOTE: only keeps other local processes from casually using the
      # loopback listener - it is not a secret, anything local can read the
      # nix store anyway
      memoryApiKey = "7c1e5b0f9a24d83e6b1f40c7a92d5e38";

      nixMcpServer = inputs.mcp-nix.packages.${system}.default;
      gitMcpServerBwrap = inputs.haraspkgs.packages.${system}.git-mcp-server-bwrap.override {
        bwrapArgs = bwrapBase;
      };
      filesystemMcpServer = inputs.haraspkgs.packages.${system}.mcp-server-filesystem-bwrap;
      memoryMcpServer = pkgs.harasPackages.mcp-memory-service;
      webMcpServer = inputs.mcp-server-web.packages.${system}.mcp-server-web;

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

      # NOTE: overlay mounts cannot nest in this sandbox, so haraspkgs tools
      # copy their generated files into the tree instead
      nixSandbox = builtins.concatStringsSep " " (
        bwrapBase
        ++ [
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
      # started in
      nixMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-nix-mcp-server";
        runtimeInputs = [ nixMcpServer ];
        text = ''
          root="$(pwd -P)"
          MCP_NIX_SANDBOX="${nixSandbox}"
          MCP_NIX_SANDBOX="''${MCP_NIX_SANDBOX//@ROOT@/$root}"
          export MCP_NIX_SANDBOX
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

      # NOTE: the models are mounted from the store where the service expects
      # its download cache, the only writable path is the memory directory,
      # and the service is configured to never go online - the network
      # namespace is only shared so clients can reach its loopback listener
      memoryEnvironment = {
        HOME = "/home/memory";
        LANG = "C.UTF-8";
        MCP_MEMORY_STORAGE_BACKEND = "sqlite_vec";
        MCP_MEMORY_BASE_DIR = "/memory";
        MCP_MEMORY_SQLITE_PATH = "/memory/sqlite_vec.db";
        MCP_MEMORY_BACKUPS_PATH = "/memory/backups";
        MCP_MEMORY_ARCHIVE_PATH = "/memory/archive";
        MCP_MEMORY_USE_ONNX = "1";
        MCP_MEMORY_ONNX_ALLOW_DOWNLOAD = "0";
        MCP_MEMORY_OFFLINE = "1";
        MCP_RERANK_ENABLED = "true";
        MCP_RERANK_MODEL = "ms-marco-MiniLM-L-6-v2";
        HF_HUB_OFFLINE = "1";
        TRANSFORMERS_OFFLINE = "1";
        MCP_CONSOLIDATION_ENABLED = "true";
        MCP_API_KEY = memoryApiKey;
      };

      memorySandbox =
        bwrapBase
        ++ [
          "--share-net"
          "--ro-bind"
          "${memoryMcpServer.onnxModel}/onnx"
          "/home/memory/.cache/mcp_memory/onnx_models/all-MiniLM-L6-v2/onnx"
          "--ro-bind"
          "${memoryMcpServer.rerankModel}"
          "/home/memory/.cache/mcp_memory/onnx_models/ms-marco-MiniLM-L-6-v2"
          "--clearenv"
        ]
        ++ lib.concatLists (
          lib.mapAttrsToList (name: value: [
            "--setenv"
            name
            value
          ]) memoryEnvironment
        );

      memoryMcpServerWrapper = pkgs.writeShellApplication {
        name = "dot-memory-mcp-server";
        runtimeInputs = [ pkgs.bubblewrap ];
        text = ''
          mkdir -p "${memoryDir}"
          exec bwrap ${lib.escapeShellArgs memorySandbox} \
            --bind "${memoryDir}" /memory \
            --chdir /memory \
            ${lib.getExe memoryMcpServer} server --streamable-http \
            --sse-host 127.0.0.1 --sse-port ${builtins.toString memoryPort} "$@"
        '';
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

          memory = {
            url = "http://127.0.0.1:${builtins.toString memoryPort}/mcp";
            headers.Authorization = "Bearer ${memoryApiKey}";
          };
        };
      };

      systemd.user.services.mcp-memory = {
        Unit.Description = "Semantic memory MCP server";

        Service = {
          ExecStart = lib.getExe memoryMcpServerWrapper;
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };
}
