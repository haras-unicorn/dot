{ pkgs, lib, config, ... }:

# FIXME: lockscreen on xserver

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    dot.desktopEnvironment.sessionStartup = [
      "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.stylix.image}'"
    ];

    services.betterlockscreen.enable = true;
  };
}
