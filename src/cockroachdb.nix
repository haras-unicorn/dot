{ config, lib, pkgs, utils, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  cfg = config.services.cockroachdb;
  crdb = cfg.package;

  # NOTE: https://github.com/NixOS/nixpkgs/pull/172923
  # NOTE: https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/databases/cockroachdb.nix
  startupCommand = utils.escapeSystemdExecArgs (
    [
      # Basic startup
      "${crdb}/bin/cockroach"
      "start-single-node"
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
  branch.nixosModule.nixosModule = {
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
      services.cockroachdb.insecure = true;

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
                text =
                  lib.concatMapStrings
                    (file: ''
                      echo "Running: ${file}"
                      ${pkgs.postgresql}/bin/psql \
                        --host ${cfg.listen.address} \
                        --port ${builtins.toString cfg.listen.port} \
                        --file "${file}"
                    '')
                    initScriptFiles;
              };
            in
            "${app}/bin/${name}";
        };
      };
    };
  };

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
}
