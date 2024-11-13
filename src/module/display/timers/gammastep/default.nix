{ config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && hasWayland) {
    services.gammastep.enable = true;
    services.gammastep.provider = "geoclue2";
    services.gammastep.tray = true;
  };
}
