{ config, lib, ... }:

let
  hasBluetooth = config.dot.hardware.bluetooth.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  config = lib.mkIf hasBluetooth {
    desktopEnvironment.windowrules = lib.mkIf hasMonitor [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = ".blueman-manager-wrapped";
      xarg = ".blueman-manager-wrapped";
    }];
  };

  integrate.nixosModule.nixosModule = lib.mkIf hasBluetooth {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasBluetooth && hasMonitor) {
    services.blueman-applet.enable = true;
  };
}
