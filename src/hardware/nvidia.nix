{ ... }:

# TODO: fix 340
# TODO: hardware.fancontrol.enable
# TODO: hardware.brillo.enable
# FIXME: https://github.com/NixOS/nixpkgs/issues/306276

{
  flake.nixosModules.hardware-nvidia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.dot.host.user;

      hasNvidia = config.dot.hardware.graphics.driver == "nvidia";
      version = config.dot.hardware.graphics.version;
      busId = config.dot.hardware.graphics.busId;

      integratedDriver = config.dot.hardware.graphics.integrated.driver;
      integratedBusId = config.dot.hardware.graphics.integrated.busId;
      hasIntegrated = integratedDriver != null && integratedBusId != null;
    in
    lib.mkIf hasNvidia {
      # NOTE: needed for early splash
      boot.initrd.availableKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
      ];
      boot.kernelParams = [
        "nvidia_drm.modeset=1"
      ];
      boot.kernelModules = [
        "nvidia_uvm" # NOTE: sometimes CUDA forgets to auto-load
      ];

      # NOTE: needed for suspend
      boot.extraModprobeConfig = ''
        options nvidia NVreg_PreserveVideoMemoryAllocations=1
      '';
      hardware.nvidia.powerManagement.enable = true;
      systemd.services.nvidia-suspend.wantedBy = [ "sleep.target" ];
      systemd.services.nvidia-suspend.before = [ "sleep.target" ];
      systemd.services.nvidia-hibernate.wantedBy = [ "hibernate.target" ];
      systemd.services.nvidia-hibernate.before = [ "hibernate.target" ];
      systemd.services.nvidia-resume.wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
      systemd.services.nvidia-resume.after = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];

      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${version}";
      # FIXME: https://github.com/NixOS/nixpkgs/issues/429624#issuecomment-3148696289
      # also seems like this has to be false for PRIME...
      # hardware.nvidia.open = config.dot.hardware.graphics.open;
      hardware.nvidia.open = false;
      hardware.nvidia.modesetting.enable = true;
      hardware.nvidia.videoAcceleration = true;
      hardware.nvidia.nvidiaSettings = true;

      hardware.nvidia.prime.offload.enable = hasIntegrated;
      hardware.nvidia.prime.offload.enableOffloadCmd = hasIntegrated;
      hardware.nvidia.prime.nvidiaBusId = lib.mkIf hasIntegrated busId;
      hardware.nvidia.prime.amdgpuBusId = lib.mkIf (integratedDriver == "amdgpu") integratedBusId;
      hardware.nvidia.prime.intelBusId = lib.mkIf (integratedDriver == "intel") integratedBusId;

      services.xserver.videoDrivers = [ "nvidia" ];

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
        mesa-demos # NOTE: glxinfo and eglinfo
      ];

      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = "nvidia"; # NOTE: hardware acceleration
        VDPAU_DRIVER = "va_gl"; # NOTE: hardware acceleration
        GBM_BACKEND = "nvidia-drm"; # NOTE: wayland buffer api
        WLR_RENDERER = "gles2"; # NOTE: wayland roots compositor renderer

        NVD_BACKEND = "direct"; # NOTE: nvidia-vaapi-driver backend
        __GL_GSYNC_ALLOWED = "1"; # NOTE: nvidia g-sync
        __GL_VRR_ALLOWED = "1"; # NOTE: nvidia g-sync
      }
      // lib.optionalAttrs hasIntegrated {
        # NOTE: offload everything to nvidia
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
        DRI_PRIME = "1";
      };

      users.users.${user}.extraGroups = [
        "video"
      ];
    };
}
