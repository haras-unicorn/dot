{ self, ... }:

{
  flake.nixosModules.critical-vaultwarden =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      hosts = builtins.filter (
        host:
        if lib.hasAttrByPath [ "system" "dot" "vaultwarden" "enable" ] host then
          host.system.dot.vaultwarden.enable
        else
          false
      ) config.dot.host.hosts;

      port = 8222;

      # TODO: remove mention of postgres here
      package = pkgs.vaultwarden-postgresql.overrideAttrs (
        final: prev: {
          patches = (prev.patches or [ ]) ++ [
            ./2020-08-02-025025-migration.patch
            ./specify-integer-length-in-migrations.patch
          ];
        }
      );

      dataDir = "/var/lib/${config.systemd.services.vaultwarden.serviceConfig.StateDirectory}";

      vaultwardenUser = config.systemd.services.vaultwarden.serviceConfig.User;
    in
    {
      options.dot = {
        vaultwarden = {
          enable = lib.mkEnableOption "Vaultwarden";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.vaultwarden.enable) {
        services.vaultwarden.enable = true;
        services.vaultwarden.package = package;
        # TODO: remove mention of postgres here
        services.vaultwarden.dbBackend = "postgresql";
        services.vaultwarden.config = {
          ROCKET_ADDRESS = "0.0.0.0";
          ROCKET_PORT = port;
          SIGNUPS_ALLOWED = true;
          ENABLE_WEBSOCKET = false;
          DOMAIN = "https://vaultwarden.${config.dot.domains.service}";
        };
        services.vaultwarden.environmentFile = config.sops.secrets."vaultwarden-env".path;
        systemd.services.vaultwarden.wantedBy = [ "dot-database-initialized.target" ];
        systemd.services.vaultwarden.requires = [ "dot-database-initialized.target" ];
        systemd.services.vaultwarden.after = [ "dot-database-initialized.target" ];
        systemd.services.vaultwarden.serviceConfig = {
          Restart = lib.mkForce "always";
        };

        networking.firewall.allowedTCPPorts = [ port ];

        dot.services = [
          {
            name = "vaultwarden";
            port = port;
            health = "http:///alive";
          }
        ];

        dot.database.apps.vaultwarden = {
          hosts = builtins.map ({ name, ... }: name) hosts;
          user = config.systemd.services.vaultwarden.serviceConfig.User;
          group = config.systemd.services.vaultwarden.serviceConfig.User;
          init.bash.script = ''
            echo "Running vaultwarden migrations..."
            export DATABASE_URL="$(grep DATABASE_URL ${
              config.sops.secrets."vaultwarden-env".path
            } | cut -d'"' -f2)"
            export ADMIN_TOKEN="temp"
            export ROCKET_ADDRESS="127.0.0.1"
            export ROCKET_PORT="18222"
            export SIGNUPS_ALLOWED="true"
            export ENABLE_WEBSOCKET="false"
            export DATA_FOLDER="${dataDir}"
            export WEB_VAULT_ENABLED="false"
            export EXTENDED_LOGGING="true"
            export LOG_LEVEL="info"

            mkdir -p "$DATA_FOLDER"
            chown "${vaultwardenUser}:${vaultwardenUser}" "$DATA_FOLDER"

            log_file=$(mktemp)
            trap 'rm -f "$log_file"' EXIT

            runuser -u "${vaultwardenUser}" -- "${lib.getExe package}" > "$log_file" 2>&1 &
            vaultwarden_pid=$!
            migrations_done=false

            while IFS= read -r line; do
                echo "vaultwarden: $line"
                if echo "$line" | grep -q "Rocket has launched"; then
                    echo "Vaultwarden server launched"
                    migrations_done=true
                    kill $vaultwarden_pid 2>/dev/null
                    break
                fi
            done < <(tail -n +1 -f "$log_file")
            wait $vaultwarden_pid

            if [ "$migrations_done" != "true" ]; then
                echo "Vaultwarden failed before migrations completed"
                exit 1
            fi

            echo "Vaultwarden migrations completed successfully"
          '';
        };

        sops.secrets."vaultwarden-env" = {
          owner = config.systemd.services.vaultwarden.serviceConfig.User;
          group = config.systemd.services.vaultwarden.serviceConfig.User;
          mode = "0400";
        };
        sops.secrets."vaultwarden-auth-key" = {
          path = "${dataDir}/rsa_key.pem";
          owner = config.systemd.services.vaultwarden.serviceConfig.User;
          group = config.systemd.services.vaultwarden.serviceConfig.User;
          mode = "0400";
        };

        cryl.sops.keys = [
          "vaultwarden-auth-key"
          "vaultwarden-env"
        ];
        cryl.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "vaultwarden-admin-pass";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "vaultwarden-auth-key";
              allow_fail = true;
            };
          }
        ];
        cryl.specification.generations = lib.mkAfter [
          {
            generator = "script";
            arguments = {
              name = "vaultwarden-auth-key-script";
              text = ''
                openssl genrsa -out vaultwarden-auth-key 4096
              '';
            };
          }
          {
            generator = "key";
            arguments = {
              name = "vaultwarden-admin-pass";
            };
          }
          {
            generator = "moustache";
            arguments = {
              name = "vaultwarden-env";
              renew = true;
              variables = {
                DATABASE_VAULTWARDEN_URL = config.dot.database.instances.vaultwarden.urlSecret;
                ADMIN_TOKEN = "vaultwarden-admin-pass";
              };
              template = ''
                DATABASE_URL="{{DATABASE_VAULTWARDEN_URL}}"
                ADMIN_TOKEN="{{ADMIN_TOKEN}}"
              '';
            };
          }
        ];
        cryl.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "vaultwarden-admin-pass";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = self.lib.cryl.shared;
              file = "vaultwarden-auth-key";
            };
          }
        ];
      };
    };

  flake.homeModules.critical-vaultwarden =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
      # TODO: remove mention of postgres here
      package = pkgs.vaultwarden-postgresql.overrideAttrs (
        final: prev: {
          patches = (prev.patches or [ ]) ++ [
            ./2020-08-02-025025-migration.patch
            ./specify-integer-length-in-migrations.patch
          ];
        }
      );
    in
    lib.mkIf hasNetwork {
      home.packages = [
        package
        pkgs.bitwarden-cli
      ]
      ++ (lib.optional hasMonitor pkgs.bitwarden-desktop);

      xdg.desktopEntries = lib.mkIf hasMonitor {
        vaultwarden = {
          name = "Vaultwarden";
          exec =
            "${config.dot.browser.package}/bin/${config.dot.browser.bin} "
            + "--new-window vaultwarden.${config.dot.domains.service}";
          terminal = false;
        };
      };
    };
}
