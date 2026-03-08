{
  flake.homeModules.critical-cockroachdb =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasNetwork {
      home.packages = [
        pkgs.cockroachdb
        pkgs.postgresql
      ];

      xdg.desktopEntries = lib.mkIf hasMonitor {
        cockroachdb = {
          name = "CockroachDB";
          exec =
            "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
            + " --new-window cockroachdb.${config.dot.domains.service}";
          terminal = false;
        };
      };
    };
}
