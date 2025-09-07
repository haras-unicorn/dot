{
  lib,
  config,
  pkgs,
  ...
}:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  user = config.dot.user;
  vaultwardenUser = "vaultwarden_${config.dot.host.name}";
  certs = "/etc/vaultwarden/certs";
  port = 8222;
  package = pkgs.vaultwarden-postgresql.overrideAttrs (
    final: prev: {
      patches = (prev.patches or [ ]) ++ [
        ./2020-08-02-025025-migration.patch
        ./specify-integer-length-in-migrations.patch
      ];
    }
  );
  hosts = builtins.map (x: x.ip) (
    builtins.filter (
      x:
      if lib.hasAttrByPath [ "system" "dot" "vaultwarden" "coordinator" ] x then
        x.system.dot.vaultwarden.coordinator
      else
        false
    ) config.dot.hosts
  );
  firstHost = builtins.head hosts;
  consoleAddress = "${firstHost}:${builtins.toString port}";
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      package
      pkgs.bitwarden-cli
    ]
    ++ (lib.optional hasMonitor pkgs.bitwarden-desktop);

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vaultwarden = {
        name = "Vaultwarden";
        exec =
          "${config.dot.browser.package}/bin/${config.dot.browser.bin} " + "--new-window ${consoleAddress}";
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
        SIGNUPS_ALLOWED = true;
        ENABLE_WEBSOCKET = false;
        DOMAIN = "https://vaultwarden.service.consul";
      };
      services.vaultwarden.environmentFile = config.sops.secrets."vaultwarden-env".path;

      services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-vaultwarden-init".path ];
      systemd.services.vaultwarden.requires = [ "cockroachdb-init.service" ];
      systemd.services.vaultwarden.after = [ "cockroachdb-init.service" ];

      networking.firewall.allowedTCPPorts = [ port ];

      dot.consul.services = [
        {
          name = "vaultwarden";
          port = port;
          address = config.dot.host.ip;
          tags = [
            "dot.enable=true"
          ];
          check = {
            http = "http://${config.dot.host.ip}:${builtins.toString port}/alive";
            interval = "30s";
            timeout = "10s";
          };
        }
      ];

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
      sops.secrets."vaultwarden-auth-key" = {
        path = "/var/lib/vaultwarden/rsa_key.pem";
        owner = config.systemd.services.vaultwarden.serviceConfig.User;
        group = config.systemd.services.vaultwarden.serviceConfig.User;
        mode = "0400";
      };

      rumor.sops = [
        "cockroach-vaultwarden-private"
        "cockroach-vaultwarden-public"
        "cockroach-vaultwarden-pass"
        "cockroach-vaultwarden-init"
        "vaultwarden-auth-key"
        "vaultwarden-env"
      ];
      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "${user}-password";
            allow_fail = false;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "vaultwarden-auth-key";
            allow_fail = false;
          };
        }
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
              alter default privileges for all roles in schema public grant all on tables to ${vaultwardenUser};
              alter default privileges for all roles in schema public grant all on sequences to ${vaultwardenUser};
              alter default privileges for all roles in schema public grant all on functions to ${vaultwardenUser};

              grant all on all tables in schema public to ${vaultwardenUser};
              grant all on all sequences in schema public to ${vaultwardenUser};
              grant all on all functions in schema public to ${vaultwardenUser};

              alter default privileges for all roles in schema public grant all on tables to ${user};
              alter default privileges for all roles in schema public grant all on sequences to ${user};
              alter default privileges for all roles in schema public grant all on functions to ${user};

              grant all on all tables in schema public to ${user};
              grant all on all sequences in schema public to ${user};
              grant all on all functions in schema public to ${user};
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
              ADMIN_TOKEN = "${user}-password";
            };
            template =
              let
                databaseUrl =
                  "postgresql://${vaultwardenUser}:{{COCKROACH_VAULTWARDEN_PASS}}@localhost"
                  + ":${builtins.toString config.services.cockroachdb.listen.port}"
                  + "/vaultwarden"
                  + "?sslmode=verify-full"
                  + "&sslrootcert=${certs}/ca.crt"
                  + "&sslcert=${certs}/client.vaultwarden.crt"
                  + "&sslkey=${certs}/client.vaultwarden.key";
              in
              ''
                DATABASE_URL="${databaseUrl}"
                ADMIN_TOKEN="{{ADMIN_TOKEN}}"
              '';
          };
        }
      ];
    };
  };
}
