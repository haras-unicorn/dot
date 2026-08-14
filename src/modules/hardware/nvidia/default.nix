# TODO: hardware.fancontrol.enable
# TODO: hardware.brillo.enable
# FIXME: https://github.com/NixOS/nixpkgs/issues/306276

{
  machines.nixosModules.hardware-nvidia =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.dot.user.user;
      graphics = config.hardware.facter.detection.graphics;
      default = graphics.cards.default;
      integrated = graphics.cards.integrated;
      enableIntegrated = integrated != null;
      cuda = default.version == "latest" || default.version == "production";
    in
    lib.mkIf (default.type == "nvidia") {
      # NOTE: even without cuda it still asks for all these
      dot.nixpkgs.allowUnfreePredicates = [
        (
          package:
          lib.getName package == "nvidia-x11"
          || lib.getName package == "nvidia-settings"
          || lib.getName package == "cuda-merged"
          || package ? cudaMajorVersion
        )
      ];

      nixpkgs.config = {
        nvidia.acceptLicense = true;
        cudaSupport = cuda;
      };

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

      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool.json".source =
        ./50-limit-free-buffer-pool.json;

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

      hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${default.version}";
      hardware.nvidia.open = default.open;
      hardware.nvidia.modesetting.enable = true;
      hardware.nvidia.videoAcceleration = true;
      hardware.nvidia.nvidiaSettings = true;

      hardware.nvidia.prime.offload.enable = enableIntegrated;
      hardware.nvidia.prime.offload.enableOffloadCmd = enableIntegrated;
      hardware.nvidia.prime.nvidiaBusId = lib.mkIf enableIntegrated default.pci;
      hardware.nvidia.prime.amdgpuBusId = lib.mkIf (integrated.type == "amd") integrated.pci;
      hardware.nvidia.prime.intelBusId = lib.mkIf (integrated.type == "intel") integrated.pci;

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
        nvtopPackages.full # NOTE: usage tui
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
      // lib.optionalAttrs enableIntegrated {
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
