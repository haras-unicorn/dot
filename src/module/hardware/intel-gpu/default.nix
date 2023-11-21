{ pkgs, ... }:

{
  boot.initrd.kernelModules = [ "i915" ];

  services.xserver.videoDrivers = [ "intel" ];

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
    libvdpau-va-gl
  ];
  hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
    intel-media-driver
    libvdpau-va-gl
  ];

  programs.corectrl.enable = true;
  programs.corectrl.gpuOverclock.enable = true;

  environment.systemPackages = with pkgs; [
    libva
    libvdpau
    vdpauinfo
    libva-utils
    vulkan-tools
    glxinfo
    invokeai
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # NOTE: hardware acceleration
    VDPAU_DRIVER = "va_gl"; # NOTE: hardware acceleration
    GBM_BACKEND = "mesa"; # NOTE: wayland buffer api
    WLR_RENDERER = "vulkan"; # NOTE: wayland roots compositor renderer
    __GLX_VENDOR_LIBRARY_NAME = "mesa"; # NOTE: offload opengl xserver workloads to gpu
  };
}
