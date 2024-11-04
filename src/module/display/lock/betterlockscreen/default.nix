{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  shared = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.dot.wallpaper}'"
      ];
    };
  };

  home = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    services.betterlockscreen.enable = true;
  };
}
