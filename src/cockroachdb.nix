{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  cfg = config.services.cockroachdb;
  crdb = cfg.package;
  certs = "/var/lib/cockroachdb/.certs";
  databaseUrl =
    "postgresql://root@localhost"
    + ":${builtins.toString cfg.listen.port}"
    + "?sslmode=verify-full"
    + "&sslrootcert=${certs}/ca.crt"
    + "&sslcert=${certs}/client.root.crt"
    + "&sslkey=${certs}/client.root.key";
  user = config.dot.user;
  clientCerts = "${config.users.users.${user}.home}/.cockroach-certs";
  httpPort = 8080;
  port = 26257;
  hosts = builtins.map (x: x.ip) (
    builtins.filter (
      x:
      if lib.hasAttrByPath [ "system" "dot" "postgres" "coordinator" ] x then
        x.system.dot.postgres.coordinator
      else
        false
    ) config.dot.hosts
  );
  consoleAddress = "${builtins.head hosts}:${builtins.toString httpPort}";

  join = builtins.concatStringsSep "," (builtins.map (x: "${x}:${builtins.toString port}") hosts);

  # NOTE: https://github.com/NixOS/nixpkgs/pull/172923
  # NOTE: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/databases/cockroachdb.nix
  startupCommand = utils.escapeSystemdExecArgs (
    [
      # Basic startup
      "${crdb}/bin/cockroach"
      "start"
      "--background"
      "--logtostderr"
      "--store=/var/lib/cockroachdb"

      # WebUI settings
      "--http-addr=${cfg.http.address}:${toString cfg.http.port}"

      # Cluster advertise address
      # NOTE: nixos config sets listen-addr here but we dont want to set that
      # because we want to listen on all addresses
      # what we actually want is to advertise on the vpn address
      "--advertise-addr=${cfg.listen.address}:${toString cfg.listen.port}"

      # Cache and memory settings.
      "--cache=${cfg.cache}"
      "--max-sql-memory=${cfg.maxSqlMemory}"

      # Certificate/security settings.
      (if cfg.insecure then "--insecure" else "--certs-dir=${cfg.certsDir}")
    ]
    ++ lib.optional (cfg.join != null) "--join=${cfg.join}"
    ++ lib.optional (cfg.locality != null) "--locality=${cfg.locality}"
    ++ cfg.extraArgs
  );
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.cockroachdb
      pkgs.postgresql
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      cockroachdb = {
        name = "CockroachDB";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window ${consoleAddress}";
        terminal = false;
      };
    };
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      postgres.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    options.services.cockroachdb = {
      init = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of SQL scripts to execute during initialization";
      };

      initFiles = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        description = "List of SQL file paths to execute during initialization";
      };
    };

    config = lib.mkMerge [
      (lib.mkIf hasNetwork {
        sops.secrets."cockroach-${user}-ca-public" = {
          key = "cockroach-ca-public";
          path = "${clientCerts}/ca.crt";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-public" = {
          path = "${clientCerts}/client.${user}.crt";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-private" = {
          path = "${clientCerts}/client.${user}.key";
          owner = user;
          group = user;
          mode = "0400";
        };

        rumor.sops = [
          "cockroach-ca-public"
          "cockroach-${user}-private"
          "cockroach-${user}-public"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-private";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-public";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
          {
            generator = "cockroach-ca";
            arguments = {
              private = "cockroach-ca-private";
              public = "cockroach-ca-public";
            };
          }
          {
            generator = "cockroach-client";
            arguments = {
              ca_private = "cockroach-ca-private";
              ca_public = "cockroach-ca-public";
              private = "cockroach-${user}-private";
              public = "cockroach-${user}-public";
              user = user;
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-private";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-public";
            };
          }
        ];
      })
      (lib.mkIf (hasNetwork && config.dot.postgres.coordinator) {
        services.cockroachdb.enable = true;
        services.cockroachdb.join = join;
        services.cockroachdb.openPorts = true;
        services.cockroachdb.certsDir = certs;
        services.cockroachdb.http.address = config.dot.host.ip;
        services.cockroachdb.http.port = httpPort;
        services.cockroachdb.listen.address = config.dot.host.ip;

        systemd.services.cockroachdb.after = [
          "vpn-online.target"
          "time-synced.target"
        ];
        systemd.services.cockroachdb.requires = [
          "vpn-online.target"
          "time-synced.target"
        ];
        systemd.services.cockroachdb.serviceConfig.ExecStart = lib.mkForce startupCommand;
        systemd.services.cockroachdb.serviceConfig.Type = lib.mkForce "forking";

        systemd.services.cockroachdb-init = lib.mkIf (cfg.init != [ ] || cfg.initFiles != [ ]) {
          description = "CockroachDB Initialization";
          after = [ "cockroachdb.service" ];
          requires = [ "cockroachdb.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = "yes";
            User = config.systemd.services.cockroachdb.serviceConfig.User;
            ExecStart =
              let
                initScriptFiles =
                  (lib.imap1 (i: sql: pkgs.writeText "cockroach-init-${builtins.toString i}.sql" sql) cfg.init)
                  ++ cfg.initFiles;

                name = "cockroachdb-init-script";
                app = pkgs.writeShellApplication {
                  inherit name;
                  text = ''
                    ${crdb}/bin/cockroach init --certs-dir "${certs}" \
                      || echo "Cluster already initialized."
                    ${lib.concatMapStrings (file: ''
                      echo "Running: ${file}"
                      ${pkgs.postgresql}/bin/psql "${databaseUrl}" --file "${file}"
                    '') initScriptFiles}
                  '';
                };
              in
              "${app}/bin/${name}";
          };
        };
        services.cockroachdb.initFiles = lib.mkBefore [ config.sops.secrets."cockroach-init".path ];

        dot.consul.services = [
          {
            name = "cockroachdb";
            port = httpPort;
            address = config.dot.host.ip;
            tags = [
              "dot.enable=true"
            ];
            check = {
              http = "http://${config.dot.host.ip}:${builtins.toString httpPort}/health";
              interval = "30s";
              timeout = "10s";
            };
          }
        ];

        programs.rust-motd.settings = {
          service_status = {
            CockroachDB = "cockroachdb";
          };
        };

        sops.secrets."cockroach-ca-public" = {
          path = "${certs}/ca.crt";
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0644";
        };
        sops.secrets."cockroach-public" = {
          path = "${certs}/node.crt";
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0644";
        };
        sops.secrets."cockroach-private" = {
          path = "${certs}/node.key";
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0400";
        };
        sops.secrets."cockroach-root-public" = {
          path = "${certs}/client.root.crt";
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0644";
        };
        sops.secrets."cockroach-root-private" = {
          path = "${certs}/client.root.key";
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0400";
        };
        sops.secrets."cockroach-init" = {
          owner = config.systemd.services.cockroachdb.serviceConfig.User;
          group = config.systemd.services.cockroachdb.serviceConfig.User;
          mode = "0400";
        };

        rumor.sops = [
          "cockroach-private"
          "cockroach-public"
          "cockroach-init"
          "cockroach-root-private"
          "cockroach-root-public"
          "cockroach-root-pass"
          "cockroach-${user}-private"
          "cockroach-${user}-public"
          "cockroach-${user}-pass"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-root-pass";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-${user}-pass";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
          {
            generator = "key";
            arguments = {
              name = "cockroach-root-pass";
            };
          }
          {
            generator = "key";
            arguments = {
              name = "cockroach-${user}-pass";
            };
          }
          {
            generator = "moustache";
            arguments = {
              name = "cockroach-init";
              renew = true;
              variables = {
                COCKROACH_ROOT_PASS = "cockroach-root-pass";
                COCKROACH_USER_PASS = "cockroach-${user}-pass";
              };
              template = ''
                alter user root with password '{{COCKROACH_ROOT_PASS}}';
                create user if not exists ${user} password '{{COCKROACH_USER_PASS}}';
                create database if not exists ${user};

                \c ${user}
                alter default privileges in schema public grant all on tables to ${user};
                alter default privileges in schema public grant all on sequences to ${user};
                alter default privileges in schema public grant all on functions to ${user};

                grant all on all tables in schema public to ${user};
                grant all on all sequences in schema public to ${user};
                grant all on all functions in schema public to ${user};
              '';
            };
          }
          {
            generator = "cockroach";
            arguments = {
              ca_private = "cockroach-ca-private";
              ca_public = "cockroach-ca-public";
              hosts = [
                "localhost"
                "127.0.0.1"
                config.dot.host.ip
              ];
              private = "cockroach-private";
              public = "cockroach-public";
            };
          }
          {
            generator = "cockroach-client";
            arguments = {
              ca_private = "cockroach-ca-private";
              ca_public = "cockroach-ca-public";
              private = "cockroach-root-private";
              public = "cockroach-root-public";
              user = "root";
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-root-pass";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-${user}-pass";
            };
          }
        ];
      })
    ];
  };
}
