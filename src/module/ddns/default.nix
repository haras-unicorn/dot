{ ... }:

# NOTE: https://github.com/qdm12/ddns-updater/blob/master/docs/duckdns.md -> $XDG_STATE_HOME/ddns-updater/config.json

{
  system = {
    services.ddns-updater.enable = true;
  };
}
