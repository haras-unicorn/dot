{ pkgs, config, nixified-ai, ... }:

let
  invokeai = pkgs.writeShellApplication {
    name = "invokeai";
    runtimeInputs = [ ];
    text = ''
      nix run ${nixified-ai}#invokeai-nvidia
    '';
  };
in
{
  boot.initrd.availableKernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    nvidia-vaapi-driver
    libvdpau-va-gl
  ];
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    libvdpau-va-gl
  ];

  programs.corectrl.enable = true;
  programs.corectrl.gpuOverclock.enable = true;
  environment.systemPackages = with pkgs; [
    libva
    libvdpau
    vdpauinfo # NOTE: vdpauinfo
    libva-utils # NOTE: vainfo
    vulkan-tools # NOTE: vulkaninfo
    glxinfo # NOTE: glxinfo and eglinfo
    nvtop
    invokeai
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia"; # NOTE: hardware acceleration
    VDPAU_DRIVER = "va_gl"; # NOTE: hardware acceleration
    GBM_BACKEND = "nvidia-drm"; # NOTE: wayland buffer api
    WLR_RENDERER = "vulkan"; # NOTE: wayland roots compositor renderer
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # NOTE: offload opengl workloads to nvidia

    NVD_BACKEND = "direct"; # NOTE: nvidia-vaapi-driver backend
    __GL_GSYNC_ALLOWED = "1"; # NOTE: nvidia g-sync
    __GL_VRR_ALLOWED = "1"; # NOTE: nvidia g-sync
  };

  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.nvidiaSettings = true;
  hardware.nvidia.open = config.dot.hardware.nvidiaDriver.open;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${config.dot.hardware.nvidiaDriver.version}";

  programs.hyprland.enableNvidiaPatches = true;

  virtualisation.docker.enableNvidia = true;
  virtualisation.podman.enableNvidia = true;
}
