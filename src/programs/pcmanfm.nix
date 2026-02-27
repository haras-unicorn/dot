{
  flake.nixosModules.programs-pcmanfm =
    {
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasMonitor {
      services.gvfs.enable = true;
    };

  flake.homeModules.programs-pcmanfm =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      hasMonitor = config.dot.hardware.monitor.enable;

      mime = {
        "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
      };
    in
    lib.mkIf hasMonitor {
      dot.desktopEnvironment.windowrules = [
        {
          rule = "float";
          selector = "class";
          arg = "pcmanfm";
        }
      ];

      home.packages = [ pkgs.pcmanfm ];

      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;
    };
}
