{ config, ... }:

# NOTE: https://github.com/qdm12/ddns-updater/blob/master/docs/duckdns.md -> /var/lib/ddns-updater/config.json

{
  system = {
    services.ddns-updater.enable = true;
    services.ddns-updater.environment = {
      CONFIG_FILEPATH = "/etc/ddns-updater.json";
    };
  };

  home = {
    shared = {
      xdg.desktopEntries = {
        ddns-updater = {
          name = "DDNS Updater";
          exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8000";
          terminal = false;
        };
      };
    };
  };
}
