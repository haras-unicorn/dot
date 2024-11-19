{ lib, config, ... }:

# TODO: nfs first

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  system = lib.mkIf hasNetwork {
    # services.vaultwarden.enable = true;
    services.vaultwarden.dbBackend = "mysql";
    services.vaultwarden.environmentFile = "/etc/vaultwarden/config.env";
    sops.secrets."shared.warden" = {
      path = "/etc/vaultwarden/config.env";
      owner = "vaultwarden";
      group = "vaultwarden";
      mode = "0400";
    };
  };
}
