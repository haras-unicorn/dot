# TODO: HA SSL

{
  flake.homeModules.critical-vault =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasNetwork {
      home.packages = [
        pkgs.vault-bin
      ];

      xdg.desktopEntries = lib.mkIf hasMonitor {
        vault = {
          name = "Vault";
          exec =
            "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
            + " --new-window vault.${config.dot.domains.service}";
          terminal = false;
        };
      };
    };

  flake.nixosModules.critical-vault =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      hosts = builtins.filter (
        host:
        if lib.hasAttrByPath [ "system" "dot" "vault" "enable" ] host then
          host.system.dot.vault.enable
        else
          false
      ) config.dot.host.hosts;

      port = 8200;

      clusterPort = 8201;
    in
    {
      options.dot = {
        vault = {
          enable = lib.mkEnableOption "Vault";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.vault.enable) {
        services.vault.enable = true;
        services.vault.package = pkgs.vault-bin;
        services.vault.address = "0.0.0.0:${builtins.toString port}";
        # TODO: remove mentions of cockroachdb and postgres here
        # NOTE: nixpkgs requires something here but i put cockroachdb at the bottom
        services.vault.storageBackend = "postgresql";
        services.vault.extraConfig = ''
          ui = true
          api_addr = "http://${config.dot.host.ip}:${builtins.toString port}"
          cluster_addr = "http://${config.dot.host.ip}:${builtins.toString clusterPort}"
        '';
        services.vault.extraSettingsPaths = [ config.sops.secrets."vault-settings".path ];

        networking.firewall.allowedTCPPorts = [
          clusterPort
          port
        ];

        systemd.services.vault.requires = [ "dot-database-initialized.target" ];
        systemd.services.vault.after = [ "dot-database-initialized.target" ];

        dot.database.apps.vault = {
          hosts = builtins.map ({ name, ... }: name) hosts;
          user = config.systemd.services.vault.serviceConfig.User;
          group = config.systemd.services.vault.serviceConfig.User;
          init.sql.script = ''
            create table if not exists vault_kv_store (
              path string not null,
              value bytes null,
              constraint vault_kv_store_pkey primary key (path asc)
            );

            create table if not exists vault_ha_locks (
              ha_key string not null,
              ha_identity string not null,
              ha_value string null,
              valid_until timestamptz not null,
              constraint ha_key primary key (ha_key asc)
            );
          '';
        };

        dot.services = [
          {
            name = "vault";
            port = port;
            health = "http:///v1/sys/health?standbyok=true&perfstandbyok=true";
          }
        ];

        programs.rust-motd.settings = {
          service_status = {
            Vault = "vault";
          };
        };

        sops.secrets."vault-settings" = {
          owner = config.systemd.services.vault.serviceConfig.User;
          group = config.systemd.services.vault.serviceConfig.User;
          mode = "0400";
        };

        rumor.sops.keys = [
          "vault-settings"
        ];
        rumor.specification.generations = lib.mkAfter [
          {
            generator = "moustache";
            arguments = {
              name = "vault-settings";
              renew = true;
              variables = {
                DATABASE_VAULT_URL = config.dot.database.instances.vault.urlSecret;
              };
              # TODO: remove mention of cockroachdb here
              template = ''
                storage "cockroachdb" {
                  connection_url = "{{DATABASE_VAULT_URL}}"
                  ha_enabled = "true"
                }
              '';
            };
          }
        ];
      };
    };
}
