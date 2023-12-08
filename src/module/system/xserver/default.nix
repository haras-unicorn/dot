{ pkgs, sweet-theme, ... }:

# TODO: mirror wayland variables

# FIXME: uncouple sddm/qtile?

let
  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -sel clip "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -o -sel clip "$@"
    '';
  };
in
{
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "xcb";
    # NIXOS_OZONE_WL = "1";
    # WLR_NO_HARDWARE_CURSORS = "1";
    # XDG_SESSION_TYPE = "wayland";
    # MOZ_ENABLE_WAYLAND = "1";
    # NIXOS_XDG_OPEN_USE_PORTAL = "1";
    # GDK_BACKEND = "wayland";
    # CLUTTER_BACKEND = "wayland";
    # _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5ct
    libsForQt5.qt5.qtgraphicaleffects # NOTE: for sddm theme
    libsForQt5.plasma-framework # NOTE: for sddm theme

    xclip
    copy
    paste
  ];

  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.libinput.enable = true;

  services.picom.enable = true;

  xdg.portal.enable = true;
  xdg.portal.config.common.default = "*";
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
    libsForQt5.xdg-desktop-portal-kde
  ];

  xdg.sounds.enable = true;

  console.useXkbConfig = true;

  programs.dconf.enable = true;

  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.autoNumlock = true;
  services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
  services.xserver.displayManager.defaultSession = "none+qtile";

  security.pam.services.sddm.enableGnomeKeyring = true;

  services.xserver.windowManager.qtile.enable = true;
  services.xserver.windowManager.qtile.extraPackages =
    python3Packages: with python3Packages; [
      psutil
    ];
}
