# TODO: add service for tray

{
  machines.nixosModules.hardware-logitech =
    { config, ... }:
    {
      hardware.logitech.wireless.enable = config.hardware.facter.detection.logitech.enable;
      hardware.logitech.wireless.enableGraphical =
        config.hardware.facter.detection.logitech.enable
        && config.hardware.facter.detection.capabilities.graphics;
    };
}
