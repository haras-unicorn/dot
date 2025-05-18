{ lib, config, pkgs, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.user;
  certs = "/etc/vaultwarden/certs";
  port = 8222;

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
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT = port;
      ADMIN_TOKEN = "admin";
      SIGNUPS_ALLOWED = true;
      ENABLE_WEBSOCKET = false;
    };
    services.vaultwarden.environmentFile = config.sops.secrets."vaultwarden-env".path;
    services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-vaultwarden-init".path ];

    networking.firewall.allowedTCPPorts = [ port ];

    sops.secrets."vaultwarden-env" = {
      owner = config.systemd.services.vaultwarden.serviceConfig.User;
      group = config.systemd.services.vaultwarden.serviceConfig.User;
      mode = "0400";
    };
    sops.secrets."cockroach-vaultwarden-init" = {
      owner = config.systemd.services.cockroachdb.serviceConfig.User;
      group = config.systemd.services.cockroachdb.serviceConfig.User;
      mode = "0400";
    };
    sops.secrets."cockroach-vaultwarden-ca-public" = {
      key = "cockroach-ca-public";
      path = "${certs}/ca.crt";
      owner = config.systemd.services.vaultwarden.serviceConfig.User;
      group = config.systemd.services.vaultwarden.serviceConfig.User;
      mode = "0644";
    };
    sops.secrets."cockroach-vaultwarden-public" = {
      path = "${certs}/client.vaultwarden.crt";
      owner = config.systemd.services.vaultwarden.serviceConfig.User;
      group = config.systemd.services.vaultwarden.serviceConfig.User;
      mode = "0644";
    };
    sops.secrets."cockroach-vaultwarden-private" = {
      path = "${certs}/client.vaultwarden.key";
      owner = config.systemd.services.vaultwarden.serviceConfig.User;
      group = config.systemd.services.vaultwarden.serviceConfig.User;
      mode = "0400";
    };

    rumor.sops = [
      "cockroach-vaultwarden-private"
      "cockroach-vaultwarden-public"
      "cockroach-vaultwarden-pass"
      "cockroach-vaultwarden-init"
      "vaultwarden-env"
    ];
    rumor.specification.generations = [
      {
        generator = "cockroach-client";
        arguments = {
          ca_private = "cockroach-ca-private";
          ca_public = "cockroach-ca-public";
          private = "cockroach-vaultwarden-private";
          public = "cockroach-vaultwarden-public";
          user = "vaultwarden";
        };
      }
      {
        generator = "key";
        arguments = {
          name = "cockroach-vaultwarden-pass";
        };
      }
      {
        generator = "moustache";
        arguments = {
          name = "cockroach-vaultwarden-init";
          renew = true;
          variables = {
            COCKROACH_VAULTWARDEN_PASS = "cockroach-vaultwarden-pass";
          };
          template = ''
            create user if not exists vaultwarden password '{{COCKROACH_VAULTWARDEN_PASS}}';
            create database if not exists vaultwarden;

            \c vaultwarden
            grant all privileges on all tables in schema public to vaultwarden;
            grant all privileges on all sequences in schema public to vaultwarden;
            grant all privileges on all functions in schema public to vaultwarden;

            grant all privileges on all tables in schema public to ${user};
            grant all privileges on all sequences in schema public to ${user};
            grant all privileges on all functions in schema public to ${user};
          '';
        };
      }
      {
        generator = "moustache";
        arguments = {
          name = "vaultwarden-env";
          renew = true;
          variables = {
            COCKROACH_VAULTWARDEN_PASS = "cockroach-vaultwarden-pass";
          };
          template =
            let
              databaseUrl = "postgresql://vaultwarden:{{COCKROACH_VAULTWARDEN_PASS}}@localhost"
                + ":${builtins.toString config.services.cockroachdb.listen.port}"
                + "/vaultwarden"
                + "?sslmode=verify-full"
                + "&sslrootcert=${certs}/ca.crt"
                + "&sslcert=${certs}/client.vaultwarden.crt"
                + "&sslkey=${certs}/client.vaultwarden.key";
            in
            ''DATABASE_URL="${databaseUrl}"'';
        };
      }
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      package
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vaultwarden = {
        name = "Vaultwarden";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} "
          + "--new-window localhost:${builtins.toString port}";
        terminal = false;
      };
    };
  };
}
