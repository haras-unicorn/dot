{ pkgs, ... }:

{
  system = {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.blueman}/bin/blueman-applet"
      ];
    };
  };
}
