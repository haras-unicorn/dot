{ lib, config, ... }:

let
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
        CONFIG_FILEPATH = config.sops.secrets."ddns-updater-duckdns-nebula".path;
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

      sops.secrets."ddns-updater-duckdns-nebula" = {
        owner = "ddns-updater";
        group = "ddns-updater";
        mode = "0400";
      };

      rumor.sops = [ "ddns-updater-duckdns-nebula" ];
      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "ddns-updater-duckdns-nebula";
          };
        }
      ];
    };
  };
}
