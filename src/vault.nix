{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
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
    services.vault.extraSettingsPaths = [ "/etc/vault/settings.hcl" ];
    environment.etc."vault/settings.hcl".text = ''
      storage "postgresql" {
        connection_url = "postgres://vault@localhost:26257/vault?sslmode=disable"
      }
    '';
    services.cockroachdb.initFiles = [ "/etc/cockroachdb/init/vault.sql" ];
    environment.etc."cockroachdb/init/vault.sql".text = ''
      CREATE USER IF NOT EXISTS vault; 
      CREATE DATABASE IF NOT EXISTS vault;
      \c vault
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO vault;

      CREATE TABLE IF NOT EXISTS vault_kv_store (
        parent_path TEXT NOT NULL,
        path        TEXT,
        key         TEXT,
        value       BYTEA,
        CONSTRAINT pkey PRIMARY KEY (path, key)
      );
      CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);
    '';
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
