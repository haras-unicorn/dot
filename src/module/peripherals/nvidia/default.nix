{ pkgs
, config
, user
, ...
}:

# FIXME: https://github.com/NixOS/nixpkgs/issues/306276

{
  system = {
    boot.initrd.availableKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
    boot.kernelParams = [ "nvidia_drm.modeset=1" "nvidia_drm.fbdev=1" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    boot.kernelModules = [ "nvidia_uvm" ];

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.nvidiaSettings = true;
    hardware.nvidia.open = config.dot.hardware.graphics.open;
    hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${config.dot.hardware.graphics.version}";

    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
    hardware.graphics.extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libvdpau-va-gl
    ];
    hardware.graphics.extraPackages32 = with pkgs.driversi686Linux; [
      libvdpau-va-gl
    ];

    hardware.nvidia-container-toolkit.enable = true;

    environment.systemPackages = with pkgs; [
      libva
      libvdpau
      vdpauinfo # NOTE: vdpauinfo
      libva-utils # NOTE: vainfo
      vulkan-tools # NOTE: vulkaninfo
      glxinfo # NOTE: glxinfo and eglinfo
      nvtopPackages.full # NOTE: check GPU usage
    ];

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia"; # NOTE: hardware acceleration
      VDPAU_DRIVER = "va_gl"; # NOTE: hardware acceleration
      GBM_BACKEND = "nvidia-drm"; # NOTE: wayland buffer api
      WLR_RENDERER = "gles2"; # NOTE: wayland roots compositor renderer
      __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # NOTE: offload opengl workloads to nvidia

      NVD_BACKEND = "direct"; # NOTE: nvidia-vaapi-driver backend
      __GL_GSYNC_ALLOWED = "1"; # NOTE: nvidia g-sync
      __GL_VRR_ALLOWED = "1"; # NOTE: nvidia g-sync
    };

    users.users.${user}.extraGroups = [
      "video"
    ];
  };
}
