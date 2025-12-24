{
  pkgs,
  lib,
  config,
  ...
}:

# TODO: HA SSL

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.host.user;
  vaultUser = "vault_${config.dot.host.name}";
  certs = "/etc/vault/certs";
  port = 8200;
  clusterPort = 8201;
  hosts = builtins.map (x: x.ip) (
    builtins.filter (
      x:
      if lib.hasAttrByPath [ "system" "dot" "vault" "enable" ] x then x.system.dot.vault.enable else false
    ) config.dot.host.hosts
  );
  firstHost = builtins.head hosts;
  consoleAddress = "${firstHost}:${builtins.toString port}";
in
{
  homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.vault-bin
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vault = {
        name = "Vault";
        exec =
          "${config.dot.browser.package}/bin/${config.dot.browser.bin}" + " --new-window ${consoleAddress}";
        terminal = false;
      };
    };
  };

  nixosModule = {
    options.dot = {
      vault.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && config.dot.vault.enable) {
      services.vault.enable = true;
      services.vault.package = pkgs.vault-bin;
      services.vault.address = "0.0.0.0:${builtins.toString port}";
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

      systemd.services.vault.requires = [ "cockroachdb-init.service" ];
      systemd.services.vault.after = [ "cockroachdb-init.service" ];
      services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-vault-init".path ];

      dot.consul.services = [
        {
          name = "vault";
          port = port;
          address = config.dot.host.ip;
          tags = [
            "dot.enable=true"
          ];
          check = {
            http =
              "http://${config.dot.host.ip}:${toString port}/v1/sys/health"
              + "?standbyok=true&perfstandbyok=true";
            interval = "30s";
            timeout = "10s";
          };
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
      sops.secrets."cockroach-vault-init" = {
        owner = config.systemd.services.cockroachdb.serviceConfig.User;
        group = config.systemd.services.cockroachdb.serviceConfig.User;
        mode = "0400";
      };
      sops.secrets."cockroach-vault-ca-public" = {
        key = "cockroach-ca-public";
        path = "${certs}/ca.crt";
        owner = config.systemd.services.vault.serviceConfig.User;
        group = config.systemd.services.vault.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."cockroach-vault-public" = {
        path = "${certs}/client.vault.crt";
        owner = config.systemd.services.vault.serviceConfig.User;
        group = config.systemd.services.vault.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."cockroach-vault-private" = {
        path = "${certs}/client.vault.key";
        owner = config.systemd.services.vault.serviceConfig.User;
        group = config.systemd.services.vault.serviceConfig.User;
        mode = "0400";
      };

      rumor.sops.keys = [
        "cockroach-vault-private"
        "cockroach-vault-public"
        "cockroach-vault-pass"
        "cockroach-vault-init"
        "vault-settings"
      ];
      rumor.specification.generations = [
        {
          generator = "cockroach-client-cert";
          arguments = {
            renew = true;
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-vault-private";
            public = "cockroach-vault-public";
            user = vaultUser;
          };
        }
        {
          generator = "key";
          arguments = {
            name = "cockroach-vault-pass";
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "cockroach-vault-init";
            renew = true;
            variables = {
              COCKROACH_VAULT_PASS = "cockroach-vault-pass";
            };
            template = ''
              create user if not exists ${vaultUser} password '{{COCKROACH_VAULT_PASS}}';
              create database if not exists vault;

              \c vault
              alter default privileges for all roles in schema public grant all on tables to ${vaultUser};
              alter default privileges for all roles in schema public grant all on sequences to ${vaultUser};
              alter default privileges for all roles in schema public grant all on functions to ${vaultUser};

              grant all on all tables in schema public to ${vaultUser};
              grant all on all sequences in schema public to ${vaultUser};
              grant all on all functions in schema public to ${vaultUser};

              alter default privileges for all roles in schema public grant all on tables to ${user};
              alter default privileges for all roles in schema public grant all on sequences to ${user};
              alter default privileges for all roles in schema public grant all on functions to ${user};

              grant all on all tables in schema public to ${user};
              grant all on all sequences in schema public to ${user};
              grant all on all functions in schema public to ${user};

              create table if not exists vault_kv_store (
                parent_path text not null,
                path        text,
                key         text,
                value       bytea,
                constraint pkey primary key (path, key)
              );
              create index if not exists parent_path_idx on vault_kv_store (parent_path);

              create table if not exists vault_ha_locks (
                ha_key      text not null,
                ha_identity text not null,
                ha_value    text,
                valid_until timestamp with time zone not null,
                constraint ha_key primary key (ha_key)
              );
            '';
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "vault-settings";
            renew = true;
            variables = {
              COCKROACH_VAULT_PASS = "cockroach-vault-pass";
            };
            template =
              let
                databaseUrl =
                  "postgresql://${vaultUser}:{{COCKROACH_VAULT_PASS}}@localhost"
                  + ":${builtins.toString config.services.cockroachdb.listen.port}"
                  + "/vault"
                  + "?sslmode=verify-full"
                  + "&sslrootcert=${certs}/ca.crt"
                  + "&sslcert=${certs}/client.vault.crt"
                  + "&sslkey=${certs}/client.vault.key";
              in
              ''
                storage "cockroachdb" {
                  connection_url = "${databaseUrl}"
                  ha_enabled = "true"
                }
              '';
          };
        }
      ];
    };
  };
}
