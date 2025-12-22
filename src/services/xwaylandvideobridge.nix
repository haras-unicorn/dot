{
  pkgs,
  lib,
  config,
  ...
}:

# NOTE: removed from nixpkgs but keeping it here for now

let
  package = pkgs.kdePackages.xwaylandvideobridge;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  homeManagerModule = lib.mkIf (hasMonitor && hasWayland && false) {
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

    dot.desktopEnvironment.windowrules = [
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
