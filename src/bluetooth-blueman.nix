{ config, lib, ... }:

let
  hasBluetooth = config.dot.hardware.bluetooth.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasBluetooth {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasBluetooth && hasMonitor) {
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
