{ lib, config, ... }:

# FIXME: fix tray is not available on boot

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    networking.firewall.allowedTCPPorts = [
      8384
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    services.syncthing.enable = true;
    # services.syncthing.tray.enable = true;

    xdg.desktopEntries = lib.mkIf hasMonitor {
      syncthing = {
        name = "Syncthing";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8384";
        terminal = false;
      };
    };
  };
}
