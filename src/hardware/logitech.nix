{ config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasLogitech = config.dot.hardware.logitech.enable;
in
{
  nixosModule = {
    hardware.logitech.wireless.enable = hasLogitech;
    hardware.logitech.wireless.enableGraphical = hasMonitor && hasLogitech;
  };
}
