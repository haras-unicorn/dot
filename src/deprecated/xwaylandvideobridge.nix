{
  self.lib.deprecated.homeModules.xwaylandvideobridge =
    {
      lib,
      osConfig,
      pkgs,
      ...
    }:
    let
      package = pkgs.kdePackages.xwaylandvideobridge;
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf (hardware.graphics && hardware.wayland && false) {
      systemd.user.services.xwaylandvideobridge = {
        Unit = {
          Description = "xwaylandvideobridge";
          Requires = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${package}/bin/xwaylandvideobridge";
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };

      dot.desktop.windowrules = [
        {
          rule = "hide";
          selector = "class";
          arg = "xwaylandvideobridge";
        }
      ];

      home.packages = [
        package
      ];
    };
}
