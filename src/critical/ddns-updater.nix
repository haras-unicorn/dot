{ lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.ddns.enable;

  httpPort = 8000;
  healthPort = 9999;
in
{
  nixosModule = {
    options.dot = {
      ddns.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && isCoordinator) {
      services.ddns-updater.enable = true;
      services.ddns-updater.environment = {
        CONFIG_FILEPATH = config.sops.secrets."ddns-updater-settings".path;
        LISTENING_ADDRESS = ":${builtins.toString httpPort}";
        HEALTH_SERVER_ADDRESS = ":${builtins.toString healthPort}";
        RESOLVER_ADDRESS = "1.1.1.1:53";
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

      networking.firewall.allowedTCPPorts = [
        httpPort
        healthPort
      ];

      dot.consul.services = [
        {
          name = "ddns-updater";
          port = httpPort;
          address = config.dot.host.ip;
          tags = [
            "dot.enable=true"
          ];
          check = {
            http = "http://${config.dot.host.ip}:${builtins.toString healthPort}";
            interval = "30s";
            timeout = "10s";
          };
        }
      ];

      sops.secrets."ddns-updater-settings" = {
        owner = "ddns-updater";
        group = "ddns-updater";
        mode = "0400";
      };

      rumor.sops.keys = [ "ddns-updater-settings" ];
      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "ddns-updater-duckdns";
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "ddns-updater-cloudflare";
          };
        }
      ];
      rumor.specification.generations = [
        {
          generator = "moustache";
          arguments = {
            name = "ddns-updater-settings";
            renew = true;
            variables = {
              DUCKDNS = "ddns-updater-duckdns";
              CLOUDFLARE = "ddns-updater-cloudflare";
            };
            template = ''
              {
                "settings": [
                  {{DUCKDNS}},
                  {{CLOUDFLARE}}
                ]
              }
            '';
          };
        }
      ];
    };
  };
}
