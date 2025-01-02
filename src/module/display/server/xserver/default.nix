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
    name = "paste";
    runtimeInputs = [ pkgs.xclip ];
    text = ''
      xclip -o -sel clip "$@"
    '';
  };

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  config = lib.mkIf (hasMonitor && !hasWayland) {
    desktopEnvironment.sessionVariables = {
      QT_QPA_PLATFORM = "xcb";
    };
  };

  system = lib.mkIf (hasMonitor && !hasWayland) {
    services.xserver.enable = true;
  };

  home = lib.mkIf (hasMonitor && !hasWayland) {
    home.packages = [
      pkgs.libsForQt5.qt5ct

      pkgs.xclip
      copy
      paste

      pkgs.libnotify
    ];
  };
}
