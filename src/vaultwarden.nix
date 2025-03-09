{ lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  integrate.nixosModule.nixosModule = lib.mkIf (hasNetwork && false) {
    services.vaultwarden.enable = true;
    users.users.vaultwarden.uid = 988;
    users.groups.vaultwarden.gid = 977;
    services.vaultwarden.dbBackend = "mysql";
    services.vaultwarden.environmentFile = "/etc/vaultwarden/config.env";
    services.vaultwarden.config = {
      DATA_FOLDER = "/var/lib/vaultwarden";
    };
    systemd.services.vaultwarden.serviceConfig.StateDirectory = lib.mkForce "/var/lib/vaultwarden";
    systemd.services.vaultwarden.serviceConfig.StateDirectoryMode = lib.mkForce "0700";
    sops.secrets."shared.warden" = {
      path = "/etc/vaultwarden/config.env";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
