{ pkgs, lib, config, ... }:

let
  cfg = config.dot.desktopEnvironment;

  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      cat | wl-copy "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.wl-clipboard ];
    text = ''
      wl-paste "$@"
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  shared = lib.mkIf (hasMonitor && hasWayland) {
    dot = {
      desktopEnvironment.sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        NIXOS_OZONE_WL = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_XDG_OPEN_USE_PORTAL = "1";
        GDK_BACKEND = "wayland,x11";
        CLUTTER_BACKEND = "wayland";
        SDL_VIDEODRIVER = "wayland,x11";
        _JAVA_AWT_WM_NONREPARENTING = "1";
      };
    };
  };

  system = lib.mkIf (hasMonitor && hasWayland) {
    services.greetd.enable = true;
    services.greetd.settings = {
      default_session = {
        command = cfg.login;
      };
    };
  };

  home = lib.mkIf (hasMonitor && hasWayland) {
    home.packages = [
      pkgs.egl-wayland
      pkgs.xwaylandvideobridge

      pkgs.libsForQt5.qt5ct
      pkgs.qt6.qtwayland
      pkgs.libsForQt5.qt5.qtwayland

      pkgs.wev

      pkgs.wl-clipboard
      pkgs.xclip
      copy
      paste

      pkgs.libnotify

      pkgs.libdecor
    ];
  };
}
