{ pkgs, nixified-ai, ... }:

let
  invokeai = pkgs.makeShellApplication {
    name = "invokeai";
    runtimeInputs = [ ];
    text = ''
      nix run ${nixified-ai}#invokeai-nvidia
    '';
  };
  koboldai = pkgs.makeShellApplication {
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
  hardware.nvidia.open = true;

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
    invokeai
    koboldai
  ];

  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia";
    VDPAU_DRIVER = "nvidia";
    NVD_BACKEND = "direct";
    # GBM_BACKEND = "nvidia-drm";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
