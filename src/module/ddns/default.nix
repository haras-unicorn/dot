{ ... }:

# NOTE: https://github.com/qdm12/ddns-updater/blob/master/docs/duckdns.md -> /var/lib/ddns-updater/config.json

{
  system = {
    services.ddns-updater.enable = true;
    services.ddns-updater.environment = {
      CONFIG_FILEPATH = "/etc/ddns-updater.json";
    };
  };
}
