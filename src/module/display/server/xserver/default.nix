{ pkgs, lib, config, ... }:

let
  copy = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      cat | xclip -sel clip "$@"
    '';
  };

  paste = pkgs.writeShellApplication {
    name = "copy";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -o -sel clip "$@"
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  system = lib.mkIf (hasMonitor && !hasWayland) {
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

      xclip
      copy
      paste

      libnotify
    ];

    services.xserver.enable = true;
  };
}
