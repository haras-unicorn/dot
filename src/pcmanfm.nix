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
  branch.nixosModule.nixosModule = lib.mkIf hasMonitor {
    services.gvfs.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        xselector = "wm_class";
        arg = "pcmanfm";
        xarg = "pcmanfm";
      }
    ];

    home.packages = [ pkgs.pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
