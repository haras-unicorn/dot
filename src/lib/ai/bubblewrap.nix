{
  self.lib.ai.bubblewrap = {
    flags = {
      nvidia = [
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

      base = [
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
        "--tmpfs"
        "/tmp"
        "--proc"
        "/proc"
        "--dev"
        "/dev"
      ];
    };
  };
}
