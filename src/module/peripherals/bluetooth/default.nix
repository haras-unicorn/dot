{ pkgs, config, lib, ... }:

let
  hasBluetooth = config.dot.hardware.bluetooth.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  shared.dot = lib.mkIf hasBluetooth {
    desktopEnvironment.sessionStartup = lib.mkIf hasMonitor [
      "${pkgs.blueman}/bin/blueman-applet"
    ];
    desktopEnvironment.windowrules = lib.mkIf hasMonitor [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = ".blueman-manager-wrapped";
      xarg = ".blueman-manager-wrapped";
    }];
  };

  system = lib.mkIf hasBluetooth {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
