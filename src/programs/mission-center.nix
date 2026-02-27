{ ... }:

{
  flake.homeModules.programs-mission-center =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasMonitor {
      home.packages = [
        pkgs.mission-center
      ];

      dot.desktopEnvironment.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "io.missioncenter.MissionCenter";
        }
      ];

      dot.desktopEnvironment.monitor = "${pkgs.mission-center}/bin/missioncenter";
    };
}
