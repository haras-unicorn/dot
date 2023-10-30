{ pkgs, sweet-theme, ... }:

{
  environment.systemPackages = with pkgs; [
    xclip
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.plasma-framework
  ];

  services.picom.enable = true;
  programs.dconf.enable = true;
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;
  console.useXkbConfig = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoNumlock = true;
  services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  security.pam.services.sddm.enableGnomeKeyring = true;
  services.xserver.displayManager.defaultSession = "xfce+qtile";

  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.desktopManager.xfce.noDesktop = true;
  services.xserver.desktopManager.xfce.enableScreensaver = false;
  services.xserver.desktopManager.xfce.enableXfwm = false;

  services.xserver.windowManager.qtile.enable = true;
  services.xserver.windowManager.qtile.extraPackages =
    python3Packages: with python3Packages; [
      psutil
    ];
}
