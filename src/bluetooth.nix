{ config, lib, ... }:

let
  hasBluetooth = config.dot.hardware.bluetooth.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  integrate.nixosModule.nixosModule = lib.mkIf hasBluetooth {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasBluetooth && hasMonitor) {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = ".blueman-manager-wrapped";
      xarg = ".blueman-manager-wrapped";
    }];

    services.blueman-applet.enable = true;
  };
}
