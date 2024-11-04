{ config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && !hasWayland) {
    services.redshift.enable = true;
    services.redshift.provider = "geoclue2";
  };
}
