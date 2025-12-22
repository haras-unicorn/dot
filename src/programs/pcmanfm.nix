{
  pkgs,
  config,
  lib,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  mime = {
    "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
  };
in
{
  nixosModule = lib.mkIf hasMonitor {
    services.gvfs.enable = true;
  };

  homeManagerModule = lib.mkIf hasMonitor {
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
