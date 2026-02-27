# FIXME: fix tray is not available on boot

{
  flake.nixosModules.services-syncthing =
    {
      lib,
      config,
      flake,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    lib.mkIf hasNetwork {
      networking.firewall.allowedTCPPorts = [
        8384
      ];
    };

  flake.homeModules.services-syncthing =
    {
      lib,
      config,
      flake,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasNetwork {
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
