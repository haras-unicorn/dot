{ config, lib, pkgs, utils, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  cfg = config.services.cockroachdb;
  crdb = cfg.package;
  dot = config.dot.postgres;
  certs = "/var/lib/cockroachdb/.certs";

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

      # Cluster listen address
      "--listen-addr=${cfg.listen.address}:${toString cfg.listen.port}"

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
          exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8080";
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

    config = {
      services.cockroachdb.enable = true;
      services.cockroachdb.join = join;
      services.cockroachdb.openPorts = true;
      services.cockroachdb.certsDir = certs;

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
                  ${if dot.coordinator
                  then ''
                    if ! cockroach node status --insecure --host="${cfg.listen.address}:${builtins.toString cfg.listen.port}" 2>&1 | grep -q 'cluster not initialized'; then
                      echo "Cluster already initialized."
                    else
                      echo "Cluster not initialized, initializing..."
                      if cockroach init --insecure --host="${cfg.listen.address}:${builtins.toString cfg.listen.port}"; then
                        echo "Cluster initialized successfully."
                      else
                        echo "Failed to initialize cluster." >&2
                        exit 1
                      fi
                    fi
                  ''
                  else""}
                  ${lib.concatMapStrings
                    (file: ''
                      echo "Running: ${file}"
                      ${pkgs.postgresql}/bin/psql \
                        --host ${cfg.listen.address} \
                        --port ${builtins.toString cfg.listen.port} \
                        --file "${file}"
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

      rumor.sops = [
        "cockroach-ca-public"
        "cockroach-private"
        "cockroach-public"
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
      rumor.specification.generations = [{
        generator = "cockroach";
        arguments = {
          ca_private = "cockroach-ca-private";
          ca_public = "cockroach-ca-public";
          hosts = [ "localhost" "127.0.0.1" config.dot.host.ip ];
          private = "cockroach-private";
          public = "cockroach-public";
        };
      }];
    };
  };
}
