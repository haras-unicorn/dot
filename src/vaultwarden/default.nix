{ lib, config, pkgs, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.user;
  vaultwardenUser = "vaultwarden_${config.dot.host.name}";
  certs = "/etc/vaultwarden/certs";
  port = 8222;
  package = pkgs.vaultwarden-postgresql.overrideAttrs (final: prev: {
    patches = (prev.patches or [ ]) ++ [
      ./2020-08-02-025025-migration.patch
      ./specify-integer-length-in-migrations.patch
    ];
  });
  hosts = builtins.map
    (x: x.ip)
    (builtins.filter
      (x:
        if lib.hasAttrByPath [ "system" "dot" "vaultwarden" "coordinator" ] x
        then x.system.dot.vaultwarden.coordinator
        else false)
      config.dot.hosts);
  firstHost = builtins.head hosts;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      package
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vaultwarden = {
        name = "Vaultwarden";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} "
          + "--new-window ${firstHost}:${builtins.toString port}";
        terminal = false;
      };
    };
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      vaultwarden.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && config.dot.vaultwarden.coordinator) {
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
      dot.nginx.locations = { "/vaultwarden" = { inherit port; }; };

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
            renew = true;
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-vaultwarden-private";
            public = "cockroach-vaultwarden-public";
            user = vaultwardenUser;
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
              create user if not exists ${vaultwardenUser} password '{{COCKROACH_VAULTWARDEN_PASS}}';
              create database if not exists vaultwarden;

              \c vaultwarden
              alter default privileges in schema public grant all on tables to ${vaultwardenUser};
              alter default privileges in schema public grant all on sequences to ${vaultwardenUser};
              alter default privileges in schema public grant all on functions to ${vaultwardenUser};

              alter default privileges in schema public grant all on tables to ${user};
              alter default privileges in schema public grant all on sequences to ${user};
              alter default privileges in schema public grant all on functions to ${user};
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
                databaseUrl = "postgresql://${vaultwardenUser}:{{COCKROACH_VAULTWARDEN_PASS}}@localhost"
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
  };
}
