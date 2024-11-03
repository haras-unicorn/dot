{ lib, config, ... }:

# FIXME: fix tray is not available on boot

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  home = lib.mkIf hasNetwork {
    services.syncthing.enable = true;
    services.syncthing.tray.enable = true;

    xdg.desktopEntries = lib.mkIf (hasMonitor && hasKeyboard) {
      syncthing = {
        name = "Syncthing";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8384";
        terminal = false;
      };
    };
  };
}
