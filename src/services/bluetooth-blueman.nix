{
  flake.nixosModules.services-bluetooth-blueman =
    { config, lib, ... }:
    let
      hasBluetooth = config.dot.hardware.bluetooth.enable;
    in
    lib.mkIf hasBluetooth {
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };

  flake.homeModules.services-bluetooth-blueman =
    { config, lib, ... }:
    let
      hasBluetooth = config.dot.hardware.bluetooth.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf (hasBluetooth && hasMonitor) {
      dot.desktopEnvironment.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = ".blueman-manager-wrapped";
        }
      ];

      services.blueman-applet.enable = true;
    };
}
