{ config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  system = lib.mkIf (hasMonitor && hasWayland) {
    services.avahi.enable = true; # NOTE: https://github.com/NixOS/nixpkgs/issues/329522
    services.geoclue2.enable = true;
  };

  home = lib.mkIf (hasMonitor && hasWayland) {
    services.gammastep.enable = true;
    services.gammastep.provider = "geoclue2";
    services.gammastep.tray = true;
  };
}
