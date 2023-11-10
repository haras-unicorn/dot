{ pkgs, config, nixified-ai, ... }:

let
  invokeai = pkgs.writeShellApplication {
    name = "invokeai";
    runtimeInputs = [ ];
    text = ''
      nix run ${nixified-ai}#invokeai-nvidia
    '';
  };
  koboldai = pkgs.writeShellApplication {
    name = "koboldai";
    runtimeInputs = [ ];
    text = ''
      nix run ${nixified-ai}#koboldai-nvidia
    '';
  };
in
{
  boot.initrd.availableKernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    nvidia-vaapi-driver
    vaapiVdpau
    libvdpau-va-gl
  ];
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    vaapiVdpau
    libvdpau-va-gl
  ];
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.nvidiaSettings = true;
  # hardware.nvidia.open = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages."${config.dot.hardware.nvidiaDriver}";

  programs.corectrl.enable = true;
  programs.corectrl.gpuOverclock.enable = true;

  programs.hyprland.enableNvidiaPatches = true;

  virtualisation.docker.enableNvidia = true;
  virtualisation.podman.enableNvidia = true;

  environment.systemPackages = with pkgs; [
    libva
    libvdpau
    vdpauinfo
    libva-utils
    vulkan-tools
    invokeai
    koboldai
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    VDPAU_DRIVER = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    WLR_RENDERER = "vulkan";
    ENABLE_VKBASALT = "1";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };
}
