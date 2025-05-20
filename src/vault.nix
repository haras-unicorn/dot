{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.user;
  vaultUser = "vault_${config.dot.host.name}";
  certs = "/etc/vault/certs";
  port = 8200;
  haPort = 23886;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.vault.enable = true;
    services.vault.package = pkgs.vault-bin;
    services.vault.address = "127.0.0.1:${builtins.toString port}";
    systemd.services.vault.after = [ "cockroachdb-init.service" ];
    systemd.services.vault.wants = [ "cockroachdb-init.service" ];
    services.vault.storageBackend = "postgresql";
    services.vault.extraConfig = ''
      ui = true
      api_addr = "http://${config.dot.host.ip}:${builtins.toString haPort}"
    '';
    services.vault.extraSettingsPaths = [ config.sops.secrets."vault-settings".path ];

    networking.firewall.allowedTCPPorts = [ haPort ];
    dot.nginx.locations = { "/vault" = { inherit port; }; };

    services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-vault-init".path ];

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

    rumor.sops = [
      "cockroach-vault-private"
      "cockroach-vault-public"
      "cockroach-vault-pass"
      "cockroach-vault-init"
      "vault-settings"
    ];
    rumor.specification.generations = [
      {
        generator = "cockroach-client";
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
            alter default privileges in schema public grant all on tables to ${vaultUser};
            alter default privileges in schema public grant all on sequences to ${vaultUser};
            alter default privileges in schema public grant all on functions to ${vaultUser};

            alter default privileges in schema public grant all on tables to ${user};
            alter default privileges in schema public grant all on sequences to ${user};
            alter default privileges in schema public grant all on functions to ${user};

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
              databaseUrl = "postgresql://${vaultUser}:{{COCKROACH_VAULT_PASS}}@localhost"
                + ":${builtins.toString config.services.cockroachdb.listen.port}"
                + "/vault"
                + "?sslmode=verify-full"
                + "&sslrootcert=${certs}/ca.crt"
                + "&sslcert=${certs}/client.vault.crt"
                + "&sslkey=${certs}/client.vault.key";
            in
            ''
              storage "postgresql" {
                connection_url = "${databaseUrl}"
                ha_enabled = "true"
              }
            '';
        };
      }
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.vault-bin
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vault = {
        name = "Vault";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8200";
        terminal = false;
      };
    };
  };
}
