{
  flake.homeModules.programs-stable-diffusion-cpp =
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
      home.packages = [
        unstablePkgs.stable-diffusion-cpp
      ];
    };
}
