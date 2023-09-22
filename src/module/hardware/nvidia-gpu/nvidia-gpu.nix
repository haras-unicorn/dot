{ ... }:

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
  hardware.nvidia.modesetting.enable = true;

  programs.corectrl.enable = true;
  programs.corectrl.gpuOverclock.enable = true;

  programs.hyprland.enableNvidiaPatches = true;

  virtualisation.docker.enableNvidia = true;
}
