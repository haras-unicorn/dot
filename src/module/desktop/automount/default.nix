{ config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  home = {
    services.udiskie.enable = true;
    services.udiskie.tray = lib.mkIf hasMonitor "always";
    services.udiskie.automount = true;
    services.udiskie.notify = true;
  };
}
