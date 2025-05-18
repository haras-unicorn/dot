{ config, lib, pkgs, utils, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  cfg = config.services.cockroachdb;
  crdb = cfg.package;
  certs = "/var/lib/cockroachdb/.certs";
  databaseUrl = "postgresql://root@localhost"
    + ":${builtins.toString cfg.listen.port}"
    + "?sslmode=verify-full"
    + "&sslrootcert=${certs}/ca.crt"
    + "&sslcert=${certs}/client.root.crt"
    + "&sslkey=${certs}/client.root.key";
  user = config.dot.user;
  clientCerts = "${config.users.users.${user}.home}/.cockroach-certs";
  httpPort = 8080;
  hosts = builtins.map
    (x: x.ip)
    (builtins.filter
      (x: x.ip != config.dot.host.ip)
      (builtins.filter
        (x:
          if lib.hasAttrByPath [ "system" "dot" "postgres" "coordinator" ] x
          then x.system.dot.postgres.coordinator
          else false)
        config.dot.hosts));
  consoleAddress = "${builtins.head hosts}:${httpPort}";

  join = builtins.concatStringsSep
    ","
    hosts;

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
  branch.homeManagerModule.homeManagerModule = lib.mkIf
    hasNetwork
    {
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
          group = "users";
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-public" = {
          path = "${clientCerts}/client.${user}.crt";
          owner = user;
          group = "users";
          mode = "0644";
        };
        sops.secrets."cockroach-${user}-private" = {
          path = "${clientCerts}/client.${user}.key";
          owner = user;
          group = "users";
          mode = "0400";
        };

        rumor.sops = [
          "cockroach-${user}-private"
          "cockroach-${user}-public"
        ];
        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-private";
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "cockroach-ca-public";
            };
          }
        ];
        rumor.specification.generations = [
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
      })
      (lib.mkIf (hasNetwork && config.dot.postgres.coordinator) {
        services.cockroachdb.enable = true;
        services.cockroachdb.join = join;
        services.cockroachdb.openPorts = true;
        services.cockroachdb.certsDir = certs;
        services.cockroachdb.http.address = config.dot.host.ip;
        services.cockroachdb.http.port = httpPort;
        services.cockroachdb.listen.address = config.dot.host.ip;

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
            ExecStart =
              let
                initScriptFiles =
                  (lib.imap1
                    (i: sql:
                      pkgs.writeText
                        "cockroach-init-${builtins.toString i}.sql"
                        sql)
                    cfg.init)
                  ++ cfg.initFiles;

                name = "cockroachdb-init-script";
                app = pkgs.writeShellApplication {
                  inherit name;
                  text = ''
                    cockroach init --certs-dir "${certs}" \
                      || echo "Cluster already initialized."
                    export DATABASE_URL="${databaseUrl}"
                    ${lib.concatMapStrings
                      (file: ''
                        echo "Running: ${file}"
                        ${pkgs.postgresql}/bin/psql --file "${file}"
                      '')
                      initScriptFiles}
                  '';
                };
              in
              "${app}/bin/${name}";
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

        rumor.sops = [
          "cockroach-ca-public"
          "cockroach-private"
          "cockroach-public"
          "cockroach-root-private"
          "cockroach-root-public"
        ];
        rumor.specification.generations = [
          {
            generator = "cockroach";
            arguments = {
              ca_private = "cockroach-ca-private";
              ca_public = "cockroach-ca-public";
              hosts = [ "localhost" "127.0.0.1" config.dot.host.ip ];
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
      })
    ];
  };
}
