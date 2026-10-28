{ inputs, ... }:

{
  self.overlays.overlays.ai-mcp.value = final: prev: {
    ai-mcp =
      {
        lib,
        hardware,
        rootRef,
        sshDir,
      }:
      let
        pkgs = final;
        system = pkgs.stdenv.hostPlatform.system;

        nixMcpServer = inputs.mcp-nix.packages.${system}.default;
        gitMcpServerBwrap = inputs.haraspkgs.packages.${system}.git-mcp-server-bwrap.override {
          bwrapArgs = bwrapBase;
        };
        filesystemMcpServer = inputs.haraspkgs.packages.${system}.mcp-server-filesystem-bwrap;

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

        nixSandbox = builtins.concatStringsSep " " (
          bwrapBase
          ++ [
            "--bind"
            "@ROOT@"
            "@ROOT@"
          ]
          ++ lib.optionals hardware.cuda bwrapNvidia
        );

        nixMcpServerWrapper = pkgs.writeShellApplication {
          name = "dot-nix-mcp-server";
          runtimeInputs = [ nixMcpServer ];
          text = ''
            DOT_MCP_ROOT="''${DOT_MCP_ROOT:-$(pwd -P)}"
            export DOT_MCP_ROOT
            MCP_NIX_SANDBOX="${nixSandbox}"
            MCP_NIX_SANDBOX="''${MCP_NIX_SANDBOX//@ROOT@/$DOT_MCP_ROOT}"
            export MCP_NIX_SANDBOX
            exec ${lib.getExe nixMcpServer} "$@"
          '';
        };

        gitMcpServerWrapper = pkgs.writeShellApplication {
          name = "dot-git-mcp-server";
          runtimeInputs = [ gitMcpServerBwrap ];
          text = ''
            GIT_BASE_DIR="''${GIT_BASE_DIR:-$(pwd -P)}"
            export GIT_BASE_DIR
            exec ${lib.getExe gitMcpServerBwrap} "$@"
          '';
        };

        filesystemMcpServerWrapper = pkgs.writeShellApplication {
          name = "dot-filesystem-mcp-server";
          runtimeInputs = [ filesystemMcpServer ];
          text = ''
            FS_BASE_DIR="''${FS_BASE_DIR:-$(pwd -P)}"
            export FS_BASE_DIR
            exec ${lib.getExe filesystemMcpServer} "$@"
          '';
        };
      in
      {
        git = {
          command = [ (lib.getExe gitMcpServerWrapper) ];
          environment = {
            GIT_BASE_DIR = rootRef;
            GIT_SSH_DIR = sshDir;
          };
        };

        filesystem = {
          command = [ (lib.getExe filesystemMcpServerWrapper) ];
          environment = {
            FS_BASE_DIR = rootRef;
          };
        };

        nix = {
          command = [ (lib.getExe nixMcpServerWrapper) ];
          environment = { };
        };
      };
  };
}
