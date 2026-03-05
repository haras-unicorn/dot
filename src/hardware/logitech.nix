# TODO: add service for tray

{
  flake.nixosModules.hardware-logitech =
    { config, ... }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasLogitech = config.dot.hardware.logitech.enable;
    in
    {
      hardware.logitech.wireless.enable = hasLogitech;
      hardware.logitech.wireless.enableGraphical = hasMonitor && hasLogitech;
    };
}
