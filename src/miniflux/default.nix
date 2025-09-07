{
  lib,
  config,
  pkgs,
  ...
}:

let
  hasNetwork = config.dot.hardware.network.enable;
  user = config.dot.user;
  minifluxUser = "miniflux_${config.dot.host.name}";
  certs = "/etc/miniflux/certs";
  # NOTE: 8080 is cockroachdb, 8081 is seaweedfs
  port = 8082;
  package = pkgs.miniflux.overrideAttrs (
    final: prev: {
      patches = (prev.patches or [ ]) ++ [
        ./remove-users-extra-table.patch
        ./keep-user-session-ip-as-text.patch
        ./remove-setweight.patch
        ./separarate-out-backfills-and-enum-creation.patch
        ./double-tap-conversion-fix.patch
        ./fix-url-indices.patch
      ];
    }
  );
  package-admin = pkgs.writeShellApplication {
    name = "miniflux-admin";
    runtimeInputs = [ package ];
    text = ''
      if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
      fi

      set -o allexport
      # shellcheck source=/dev/null
      source "${config.sops.secrets."miniflux-env".path}"
      set +o allexport
      exec miniflux "$@"
    '';
  };
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      package
      pkgs.cliflux
    ];
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      miniflux.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf (hasNetwork && config.dot.miniflux.coordinator) {
      environment.systemPackages = [
        package-admin
      ];

      services.miniflux.enable = true;
      services.miniflux.package = package;
      services.miniflux.createDatabaseLocally = false;
      services.miniflux.config = {
        LISTEN_ADDR = "0.0.0.0:${builtins.toString port}";
        RUN_MIGRATIONS = 1;
        CREATE_ADMIN = 1;
        BASE_URL = "https://miniflux.service.consul/";
      };
      # NOTE: its named adminCredentialsFile but its just an EnvironmentFile setting
      services.miniflux.adminCredentialsFile = config.sops.secrets."miniflux-env".path;

      users.users.miniflux = {
        group = "miniflux";
        description = "Miniflux service user";
        isSystemUser = true;
      };
      users.groups.miniflux = { };
      systemd.services.miniflux = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "miniflux";
          Group = "miniflux";
        };
      };

      services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-miniflux-init".path ];
      systemd.services.miniflux.requires = [ "cockroachdb-init.service" ];
      systemd.services.miniflux.after = [ "cockroachdb-init.service" ];

      networking.firewall.allowedTCPPorts = [ port ];

      dot.consul.services = [
        {
          name = "miniflux";
          port = port;
          address = config.dot.host.ip;
          tags = [
            "dot.enable=true"
          ];
          check = {
            http = "http://${config.dot.host.ip}:${builtins.toString port}/healthcheck";
            interval = "30s";
            timeout = "10s";
          };
        }
      ];

      sops.secrets."miniflux-env" = {
        owner = config.systemd.services.miniflux.serviceConfig.User;
        group = config.systemd.services.miniflux.serviceConfig.User;
        mode = "0400";
      };
      sops.secrets."cockroach-miniflux-init" = {
        owner = config.systemd.services.cockroachdb.serviceConfig.User;
        group = config.systemd.services.cockroachdb.serviceConfig.User;
        mode = "0400";
      };
      sops.secrets."cockroach-miniflux-ca-public" = {
        key = "cockroach-ca-public";
        path = "${certs}/ca.crt";
        owner = config.systemd.services.miniflux.serviceConfig.User;
        group = config.systemd.services.miniflux.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."cockroach-miniflux-public" = {
        path = "${certs}/client.miniflux.crt";
        owner = config.systemd.services.miniflux.serviceConfig.User;
        group = config.systemd.services.miniflux.serviceConfig.User;
        mode = "0644";
      };
      sops.secrets."cockroach-miniflux-private" = {
        path = "${certs}/client.miniflux.key";
        owner = config.systemd.services.miniflux.serviceConfig.User;
        group = config.systemd.services.miniflux.serviceConfig.User;
        mode = "0400";
      };

      rumor.sops = [
        "cockroach-miniflux-private"
        "cockroach-miniflux-public"
        "cockroach-miniflux-pass"
        "cockroach-miniflux-init"
        "miniflux-env"
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
      ];
      rumor.specification.generations = [
        {
          generator = "cockroach-client";
          arguments = {
            renew = true;
            ca_private = "cockroach-ca-private";
            ca_public = "cockroach-ca-public";
            private = "cockroach-miniflux-private";
            public = "cockroach-miniflux-public";
            user = minifluxUser;
          };
        }
        {
          generator = "key";
          arguments = {
            name = "cockroach-miniflux-pass";
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "cockroach-miniflux-init";
            renew = true;
            variables = {
              COCKROACH_MINIFLUX_PASS = "cockroach-miniflux-pass";
            };
            template = ''
              create user if not exists ${minifluxUser} password '{{COCKROACH_MINIFLUX_PASS}}';
              create database if not exists miniflux;

              \c miniflux
              alter default privileges for all roles in schema public grant all on tables to ${minifluxUser};
              alter default privileges for all roles in schema public grant all on sequences to ${minifluxUser};
              alter default privileges for all roles in schema public grant all on functions to ${minifluxUser};

              grant all on all tables in schema public to ${minifluxUser};
              grant all on all sequences in schema public to ${minifluxUser};
              grant all on all functions in schema public to ${minifluxUser};

              alter default privileges for all roles in schema public grant all on tables to ${user};
              alter default privileges for all roles in schema public grant all on sequences to ${user};
              alter default privileges for all roles in schema public grant all on functions to ${user};

              grant all on all tables in schema public to ${user};
              grant all on all sequences in schema public to ${user};
              grant all on all functions in schema public to ${user};

              -- NOTE: needed for migrations
              grant create on database miniflux to ${minifluxUser};
              grant create on schema public to ${minifluxUser};
            '';
          };
        }
        {
          generator = "moustache";
          arguments = {
            name = "miniflux-env";
            renew = true;
            variables = {
              COCKROACH_MINIFLUX_PASS = "cockroach-miniflux-pass";
              ADMIN_PASSWORD = "${user}-password";
            };
            template =
              let
                databaseUrl =
                  "postgresql://${minifluxUser}:{{COCKROACH_MINIFLUX_PASS}}@localhost"
                  + ":${builtins.toString config.services.cockroachdb.listen.port}"
                  + "/miniflux"
                  + "?sslmode=verify-full"
                  + "&sslrootcert=${certs}/ca.crt"
                  + "&sslcert=${certs}/client.miniflux.crt"
                  + "&sslkey=${certs}/client.miniflux.key";
              in
              ''
                DATABASE_URL="${databaseUrl}"
                ADMIN_USERNAME="${user}"
                ADMIN_PASSWORD="{{ADMIN_PASSWORD}}"
              '';
          };
        }
      ];
    };
  };
}
