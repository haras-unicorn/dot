{ pkgs
  # , self
  # , sweet-theme
, ...
}:

# FIXME: uncouple hyprland/greetd/gtklock/portals?

# FIXME: links not opening https://github.com/hyprwm/Hyprland/issues/3258
# tried the portals.conf in user but didn't work

{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_SESSION_TYPE = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_XDG_OPEN_USE_PORTAL = "1";
    GDK_BACKEND = "wayland";
    CLUTTER_BACKEND = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5ct
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    egl-wayland
    wl-clipboard
    wev
  ];

  xdg.portal.enable = true;
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  xdg.sounds.enable = true;

  programs.dconf.enable = true;

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  security.pam.services.gtklock = { };

  services.greetd.enable = true;
  services.greetd.settings = {
    default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${pkgs.hyprland}/bin/Hyprland";
    };
  };
}
