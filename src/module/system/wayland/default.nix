{ pkgs
  # , self
  # , sweet-theme
, config
, ...
}:

# FIXME: uncouple hyprland/greetd/gtklock/portals?

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# TODO: these commands on hyprland startup and make config for tuigreet/hyprland command
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service

# FIXME: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/467#issuecomment-1544340511

let
  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      wl-copy "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      wl-paste "$@"
    '';
  };
in
{
  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
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
    egl-wayland
    xwaylandvideobridge

    libsForQt5.qt5ct
    qt6.qtwayland
    libsForQt5.qt5.qtwayland

    wev

    wl-clipboard
    copy
    paste
  ];

  xdg.portal.enable = true;
  xdg.portal.config.common.default = "*";
  xdg.portal.xdgOpenUsePortal = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-wlr
    libsForQt5.xdg-desktop-portal-kde
    xdg-desktop-portal-gtk
  ];
  xdg.portal.wlr.enable = true;
  xdg.portal.wlr.settings.screencast = {
    output_name = config.dot.hardware.mainMonitor;
    max_fps = 60;
    chooser_type = "simple";
    chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
  };

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
