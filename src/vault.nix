{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.vault.enable = true;
    systemd.services.vault.after = [ "cockroachdb-init.service" ];
    systemd.services.vault.wants = [ "cockroachdb-init.service" ];
    services.vault.storageBackend = "postgresql";
    services.vault.extraConfig = ''
      ui = true
    '';
    services.vault.extraSettingsPaths = [ "/etc/vault/settings.hcl" ];
    environment.etc."vault/settings.hcl".text = ''
      storage "postgresql" {
        connection_url = "postgres://vault:vault@localhost:8080/vault?sslmode=disable"
      }
    '';
    services.cockroachdb.initFiles = [ "/etc/cockroachdb/init/vault.sql" ];
    environment.etc."cockroachdb/init/vault.sql".text = ''
      CREATE USER IF NOT EXISTS vault PASSWORD 'vault'; 
      CREATE DATABASE IF NOT EXISTS vault;
      ALTER DATABASE vault OWNER TO vault;
      \c vault

      CREATE TABLE IF NOT EXISTS vault_kv_store (
        parent_path TEXT COLLATE "C" NOT NULL,
        path        TEXT COLLATE "C",
        key         TEXT COLLATE "C",
        value       BYTEA,
        CONSTRAINT pkey PRIMARY KEY (path, key)
      );
      CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);
    '';
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.vault
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
