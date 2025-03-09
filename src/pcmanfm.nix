{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  mime = {
    "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
  };
in
{
  integrate.nixosModule.nixosModule = lib.mkIf hasMonitor {
    services.gvfs.enable = true;
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "pcmanfm";
      xarg = "pcmanfm";
    }];

    home.packages = [ pkgs.pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
