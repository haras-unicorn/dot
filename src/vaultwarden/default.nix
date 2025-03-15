{ lib, config, pkgs, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  package = pkgs.vaultwarden-postgresql.overrideAttrs (final: prev: {
    patches = (prev.patches or [ ]) ++ [
      ./2020-08-02-025025-migration.patch
      ./specify-integer-length-in-migrations.patch
    ];
  });
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.vaultwarden.enable = true;
    services.vaultwarden.package = package;
    services.vaultwarden.dbBackend = "postgresql";
    services.vaultwarden.config = {
      DATABASE_URL = "postgres://vaultwarden@localhost:26257/vaultwarden?sslmode=disable";
      ROCKET_ADDRESS = "::1";
      ROCKET_PORT = 8222;
      ADMIN_TOKEN = "admin";
      SIGNUPS_ALLOWED = false;
      INVITATIONS_ALLOWED = false;
      ENABLE_WEBSOCKET = false;
    };
    services.cockroachdb.initFiles = [ "/etc/cockroachdb/init/vaultwarden.sql" ];
    environment.etc."cockroachdb/init/vaultwarden.sql".text = ''
      CREATE USER IF NOT EXISTS vaultwarden; 
      CREATE DATABASE IF NOT EXISTS vaultwarden;
      \c vaultwarden
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO vaultwarden;
    '';
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      package
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vaultwarden = {
        name = "Vaultwarden";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8222";
        terminal = false;
      };
    };
  };
}
