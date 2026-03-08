{ self, ... }:

{
  flake.nixosModules.critical-ddns-updater =
    { lib, config, ... }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      isCoordinator = config.dot.ddns-updater.enable;

      httpPort = 8000;
      healthPort = 9999;
    in
    {
      options.dot = {
        ddns-updater.enable = lib.mkEnableOption "ddns-updater";
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

        dot.services = [
          {
            name = "ddns-updater";
            port = httpPort;
            health = "http://";
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
              path = self.lib.rumor.shared;
              file = "ddns-updater-duckdns";
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.rumor.shared;
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

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-ddns-updater-disabled = self.lib.test.mkTest pkgs {
        name = "critical-ddns-updater-disabled";
        dot.test.disabledService.enable = true;
        dot.test.disabledService.module = {
          imports = [
            self.nixosModules.critical-ddns-updater
          ];
        };
        dot.test.disabledService.name = "ddns-updater";
        dot.test.disabledService.config = "/run/secrets/ddns-udater-settings";
      };

      checks.test-critical-ddns-updater-enabled = self.lib.test.mkTest pkgs {
        name = "critical-ddns-updater-enabled";

        dot.test.rumor.shared.specification.generations = [
          {
            generator = "text";
            arguments = {
              name = "ddns-updater-duckdns";
              text = "1";
            };
          }
          {
            generator = "text";
            arguments = {
              name = "ddns-updater-cloudflare";
              text = "2";
            };
          }
        ];

        nodes.machine =
          { lib, ... }:
          {
            imports = [
              self.nixosModules.critical-ddns-updater
            ];

            dot.ddns-updater.enable = true;
          };
        testScript = ''
          start_all()
          machine.succeed("systemctl is-enabled ddns-updater.service")
          machine.succeed("id ddns-updater")
          machine.succeed("getent group ddns-updater")
          machine.succeed("grep 'User=ddns-updater' /etc/systemd/system/ddns-updater.service")
          machine.succeed("grep 'Group=ddns-updater' /etc/systemd/system/ddns-updater.service")
        '';
      };
    };
}
