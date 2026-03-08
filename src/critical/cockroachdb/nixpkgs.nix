{ ... }:

{
  flake.nixosModules.critical-cockroachdb-nixpkgs =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      cfg = config.services.cockroachdb;
      crdb = cfg.package;
      certs = cfg.certsDir;
      databaseUrl =
        "postgresql://root@${cfg.sql.address}"
        + ":${builtins.toString cfg.sql.port}"
        + "?sslmode=verify-full"
        + "&sslrootcert=${certs}/ca.crt"
        + "&sslcert=${certs}/client.root.crt"
        + "&sslkey=${certs}/client.root.key";
      initUrl =
        "postgresql://root@${cfg.sql.address}"
        + ":${builtins.toString cfg.sql.port}"
        + "/init"
        + "?sslmode=verify-full"
        + "&sslrootcert=${certs}/ca.crt"
        + "&sslcert=${certs}/client.root.crt"
        + "&sslkey=${certs}/client.root.key";
    in
    {
      options.services.cockroachdb = {
        init = {
          enable = lib.mkEnableOption "CockroachDB initialization";

          runner = lib.mkEnableOption "CockroachDB initialization runner";

          hash = lib.mkOption {
            type = lib.types.str;
            description = "Current initialization hash";
          };

          packages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Packages to include in the init script";
          };

          sql = {
            scripts = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of SQL scripts (as strings) to execute during initialization";
            };

            files = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "List of SQL file paths to execute during initialization";
            };
          };

          bash = {
            scripts = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of bash scripts (as strings) to execute during initialization (init node only)";
            };

            files = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = "List of bash script file paths to execute during initialization (init node only)";
            };
          };
        };

        sql.port = lib.mkOption {
          type = lib.types.port;
          default = 26258;
          description = "SQL listening port";
        };

        sql.address = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "SQL listening address";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.enable {
          networking.firewall.allowedTCPPorts = lib.optional cfg.openPorts cfg.sql.port;

          services.cockroachdb.extraArgs = [
            "--sql-addr"
            "${cfg.sql.address}:${builtins.toString cfg.sql.port}"
          ];
        })
        (lib.mkIf (cfg.enable && cfg.init.enable) {
          systemd.services.cockroachdb-initialization = {
            description = "CockroachDB Initialization";
            wantedBy = [ "cockroachdb.service" ];
            bindsTo = [ "cockroachdb.service" ];
            after = [ "cockroachdb.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              StandardOutput = "journal";
              TimeoutStartSec = "infinity";
              Restart = "on-failure";
              ExecStart = lib.getExe (
                pkgs.writeShellApplication {
                  name = "cockroachdb-initialization";
                  runtimeInputs = [
                    pkgs.coreutils
                    pkgs.gnugrep
                    pkgs.postgresql
                    pkgs.bash
                    pkgs.util-linux
                    crdb
                  ]
                  ++ cfg.init.packages;
                  text = ''
                    MAX_RETRIES=10
                    RETRY_DELAY=5
                    INIT_TIMEOUT=30
                    SCRIPT_TIMEOUT=300
                    WAIT_TIMEOUT=600
                    IS_INIT_NODE="${if cfg.init.runner then "true" else "false"}"
                    INIT_HOST="${cfg.listen.address}:${builtins.toString cfg.listen.port}"
                    CERTS_DIR="${cfg.certsDir}"
                    DATABASE_URL="${databaseUrl}"
                    INIT_URL="${initUrl}"
                    INIT_HASH="${cfg.init.hash}"
                    SQL_SCRIPTS="${
                      builtins.concatStringsSep "," (
                        (lib.imap1 (
                          i: sql: pkgs.writeText "cockroach-sql-${builtins.toString i}.sql" sql
                        ) cfg.init.sql.scripts)
                        ++ cfg.init.sql.files
                      )
                    }"
                    BASH_SCRIPTS="${
                      builtins.concatStringsSep "," (
                        (lib.imap1 (
                          i: script: pkgs.writeText "cockroach-bash-${builtins.toString i}.sh" script
                        ) cfg.init.bash.scripts)
                        ++ cfg.init.bash.files
                      )
                    }"
                    COCKROACHDB_USER=${config.systemd.services.cockroachdb.serviceConfig.User}

                    ${builtins.readFile ./init.sh}
                  '';
                }
              );
            };
          };
        })
      ];
    };
}
