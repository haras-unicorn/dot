{ pkgs, lib, config, ... }:

# FIXME: lockscreen on xserver

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  config = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    desktopEnvironment.sessionStartup = [
      "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.stylix.image}'"
    ];
  };

  home = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    services.betterlockscreen.enable = true;
  };
}
