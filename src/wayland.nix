{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    dot.desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "wayland;xcb";
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      # NOTE: xwayland uses x11 anyway and this breaks gnome xdg portal
      # GDK_BACKEND = "wayland,x11";
      CLUTTER_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland,x11";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    };

    home.packages = [
      pkgs.egl-wayland

      pkgs.libsForQt5.qt5ct
      pkgs.qt6.qtwayland
      pkgs.libsForQt5.qt5.qtwayland

      pkgs.wev

      pkgs.wl-clipboard
      pkgs.xclip

      pkgs.libnotify

      pkgs.libdecor
    ];
  };
}
