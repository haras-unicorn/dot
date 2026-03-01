{ config, ... }:

{
  flake.nixosModules.critical-ddns-updater =
    { lib, config, ... }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      isCoordinator = config.dot.ddns.enable;

      httpPort = 8000;
      healthPort = 9999;
    in
    {
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

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-ddns-updater-disabled = config.flake.lib.test.mkTest pkgs {
        name = "critical-ddns-updater-disabled";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-ddns-updater
            config.flake.nixosModules.rumor
          ];
          options.dot.hardware.network.enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
          options.dot.host.ip = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "127.0.0.1";
          };
          options.dot.host.user = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "testuser";
          };
          options.dot.consul.services = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.raw;
            default = [ ];
          };
          options.sops.secrets = pkgs.lib.mkOption {
            type = pkgs.lib.types.attrsOf (
              pkgs.lib.types.submodule {
                options.path = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                };
                options.owner = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "root";
                };
                options.group = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "root";
                };
                options.mode = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "0400";
                };
              }
            );
            default = { };
          };
          config = {
            networking.hostName = "testhost";
            # dot.ddns.enable defaults to false in the module
            users.users.testuser = {
              isNormalUser = true;
              home = "/home/testuser";
            };
          };
        };
        script = ''
          start_all()
          # When dot.ddns.enable is false, service should not be enabled
          machine.fail("systemctl is-enabled ddns-updater.service")
        '';
      };

      checks.test-critical-ddns-updater-enabled = config.flake.lib.test.mkTest pkgs {
        name = "critical-ddns-updater-enabled";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-ddns-updater
            config.flake.nixosModules.rumor
          ];
          options.dot.hardware.network.enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
          options.dot.host.ip = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "127.0.0.1";
          };
          options.dot.host.user = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "testuser";
          };
          options.dot.consul.services = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.raw;
            default = [ ];
          };
          options.sops.secrets = pkgs.lib.mkOption {
            type = pkgs.lib.types.attrsOf (
              pkgs.lib.types.submodule {
                options.path = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                };
                options.owner = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "root";
                };
                options.group = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "root";
                };
                options.mode = pkgs.lib.mkOption {
                  type = pkgs.lib.types.str;
                  default = "0400";
                };
              }
            );
            default = { };
          };
          config = {
            networking.hostName = "testhost";
            dot.ddns.enable = true;
            sops.secrets."ddns-updater-settings".path = "/run/secrets/ddns-updater-settings";
            users.users.testuser = {
              isNormalUser = true;
              home = "/home/testuser";
            };
          };
        };
        script = ''
          start_all()
          # Service should be enabled
          machine.succeed("systemctl is-enabled ddns-updater.service")
          # Verify ddns-updater user exists
          machine.succeed("id ddns-updater")
          # Verify ddns-updater group exists
          machine.succeed("getent group ddns-updater")
          # Verify systemd service has correct user configuration
          machine.succeed("grep 'User=ddns-updater' /etc/systemd/system/ddns-updater.service")
          machine.succeed("grep 'Group=ddns-updater' /etc/systemd/system/ddns-updater.service")
        '';
      };
    };
}
