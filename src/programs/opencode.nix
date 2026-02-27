{
  flake.homeModules.programs-opencode =
    {
      pkgs,
      lib,
      config,
      unstablePkgs,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasMonitor {
      programs.opencode.enable = true;
      programs.opencode.package = unstablePkgs.opencode;
    };
}
