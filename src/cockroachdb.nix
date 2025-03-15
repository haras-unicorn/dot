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
      services.cockroachdb.locality = "system=sol,planet=earth";

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
              commands =
                lib.concatMapStrings
                  (file: ''
                    echo "Running: ${file}"
                    ${crdb}/bin/cockroach sql \
                      ${if cfg.insecure then "--insecure" else "--certs-dir=${cfg.certsDir}"} \
                      --host=${cfg.listen.address}:${builtins.toString cfg.listen.port} \
                      -f "${file}" || exit 1
                  '')
                  initScriptFiles;
              script = ''
                set -euo pipefail
                ${commands}
              '';
            in
            pkgs.writeShellScript "cockroachdb-init-script" script;
        };
      };
    };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf
    hasNetwork
    {
      home.packages = [
        pkgs.cockroachdb
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
