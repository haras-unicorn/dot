{ pkgs, config, lib, ... }:

let
  hasBluetooth =
    (builtins.hasAttr "bluetooth" config.facter.report.hardware) &&
    ((builtins.length config.facter.report.hardware.bluetooth) > 0);
in
{
  shared.dot = lib.mkIf hasBluetooth {
    desktopEnvironment.sessionStartup = [
      "${pkgs.blueman}/bin/blueman-applet"
    ];
    desktopEnvironment.windowrules = [{
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
