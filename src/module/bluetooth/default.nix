{ pkgs, ... }:

{
  shared.dot = {
    desktopEnvironment.sessionStartup = [
      "${pkgs.blueman}/bin/blueman-applet"
    ];
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      arg = ".blueman-manager-wrapped";
    }];
  };

  system = {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
}
