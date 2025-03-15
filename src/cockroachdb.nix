{ config, lib, pkgs, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;

  cfg = config.services.cockroachdb;
  crdb = cfg.package;
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

      systemd.services.cockroachdb-init = lib.mkIf (cfg.init != [ ] || cfg.initFiles != [ ]) {
        description = "CockroachDB Initialization";
        after = [ "cockroachdb.service" ];
        requires = [ "cockroachdb.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
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

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.cockroachdb
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      vault = {
        name = "CockroachDB";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8080";
        terminal = false;
      };
    };
  };
}
