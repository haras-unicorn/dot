{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.user;
  certs = "/etc/vault/certs";
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.vault.enable = true;
    services.vault.package = pkgs.vault-bin;
    systemd.services.vault.after = [ "cockroachdb-init.service" ];
    systemd.services.vault.wants = [ "cockroachdb-init.service" ];
    services.vault.storageBackend = "postgresql";
    services.vault.extraConfig = ''
      ui = true
    '';
    services.vault.extraSettingsPaths = [ config.sops.secrets."vault-settings".path ];

    services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-vault-init".path ];

    sops.secrets."vault-settings" = {
      owner = config.systemd.services.vault.serviceConfig.User;
      group = config.systemd.services.vault.serviceConfig.User;
      mode = "0400";
    };
    sops.secrets."cockroach-vault-init" = {
      owner = config.systemd.services.vault.serviceConfig.User;
      group = config.systemd.services.vault.serviceConfig.User;
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
          ca_private = "cockroach-ca-private";
          ca_public = "cockroach-ca-public";
          private = "cockroach-vault-private";
          public = "cockroach-vault-public";
          user = "vault";
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
            create user if not exists vault password '{{COCKROACH_VAULT_PASS}}';
            create database if not exists vault;

            \c vault
            grant all privileges on all tables in schema public to vault;
            grant all privileges on all sequences in schema public to vault;
            grant all privileges on all functions in schema public to vault;

            grant all privileges on all tables in schema public to ${user};
            grant all privileges on all sequences in schema public to ${user};
            grant all privileges on all functions in schema public to ${user};

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
              databaseUrl = "postgresql://vault:{{COCKROACH_VAULT_PASS}}@localhost"
                + ":${builtins.toString config.services.cockroachdb.listen.port}"
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
