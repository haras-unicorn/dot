{
  flake.homeModules.programs-whisper =
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
        pkgs.whisper-cpp
      ];
    };
}
