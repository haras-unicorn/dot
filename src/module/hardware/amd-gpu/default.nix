{ pkgs
  # , nixified-ai
, gpt4all
, ...
}:

# FIXME: system for ai from flake
# FIXME: nixified-ai getting rebuilt and not using gpu

{
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    amdvlk
  ];
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    amdvlk
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
    nixified-ai.packages.x86_64-linux.invokeai-amd
    gpt4all.packages.x86_64-linux.gpt4all-chat
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi"; # NOTE: hardware acceleration
    VDPAU_DRIVER = "radeonsi"; # NOTE: hardware acceleration
    GBM_BACKEND = "mesa"; # NOTE: wayland buffer api
    WLR_RENDERER = "vulkan"; # NOTE: wayland roots compositor renderer
    __GLX_VENDOR_LIBRARY_NAME = "mesa"; # NOTE: offload opengl workloads to nvidia
  };
}
