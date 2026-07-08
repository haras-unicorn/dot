{
  machines.homeModules.mission-center =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.browser {
      home.packages = [
        pkgs.mission-center
      ];

      dot.desktop.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "io.missioncenter.MissionCenter";
        }
      ];

      dot.desktop.monitor = "${pkgs.mission-center}/bin/missioncenter";
    };
}
