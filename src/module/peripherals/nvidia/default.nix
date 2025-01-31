{ pkgs, lib, config, user, ... }:

# FIXME: https://github.com/NixOS/nixpkgs/issues/306276

let
  hasNvidia = config.dot.hardware.graphics.driver == "nvidia";
  version = config.dot.hardware.graphics.version;
in
{
  system = lib.mkIf hasNvidia {
    boot.initrd.availableKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
    boot.kernelParams = [ "nvidia_drm.modeset=1" "nvidia_drm.fbdev=1" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    boot.kernelModules = [ "nvidia_uvm" ];

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia.modesetting.enable = true;
    hardware.nvidia.nvidiaSettings = true;
    hardware.nvidia.open = config.dot.hardware.graphics.open;
    hardware.nvidia.package =
      if version != "latest"
      then config.boot.kernelPackages.nvidiaPackages."${version}"
      else
      # NOTE: https://github.com/NVIDIA/egl-wayland/issues/126#issuecomment-2594012291
        config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "560.35.03";
          sha256_64bit = "sha256-8pMskvrdQ8WyNBvkU/xPc/CtcYXCa7ekP73oGuKfH+M=";
          sha256_aarch64 = "sha256-s8ZAVKvRNXpjxRYqM3E5oss5FdqW+tv1qQC2pDjfG+s=";
          openSha256 = "sha256-/32Zf0dKrofTmPZ3Ratw4vDM7B+OgpC4p7s+RHUjCrg=";
          settingsSha256 = "sha256-kQsvDgnxis9ANFmwIwB7HX5MkIAcpEEAHc8IBOLdXvk=";
          persistencedSha256 = "sha256-E2J2wYYyRu7Kc3MMZz/8ZIemcZg68rkzvqEwFAL3fFs=";
        };

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
