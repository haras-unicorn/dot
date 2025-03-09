{ lib, config, ... }:

let
  host = config.dot.host;

  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.ddns.coordinator;
in
{
  branch.nixosModule.nixosModule = {
    options.dot = {
      ddns.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && isCoordinator) {
      services.ddns-updater.enable = true;
      services.ddns-updater.environment = {
        CONFIG_FILEPATH = "/etc/ddns-updater/config.json";
        PERIOD = "5m";
      };
      users.users.ddns-updater = {
        group = "ddns-updater";
        description = "DDNS updater service user";
        isSystemUser = true;
      };
      users.groups.ddns-updater = { };
      systemd.services.ddns-updater = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "ddns-updater";
          Group = "ddns-updater";
        };
      };
      sops.secrets."${host}.ddns" = {
        path = "/etc/ddns-updater/config.json";
        owner = "ddns-updater";
        group = "ddns-updater";
        mode = "0400";
      };
    };
  };
}
