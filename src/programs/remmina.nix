{
  flake.homeModules.programs-remmina =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasMonitor {
      home.packages = [
        pkgs.remmina
      ];
    };
}
