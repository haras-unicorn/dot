{ pkgs, config, lib, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  mime = {
    "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
  };
in
{
  config = lib.mkIf hasMonitor {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "pcmanfm";
      xarg = "pcmanfm";
    }];
  };

  integrate.nixosModule.nixosModule = lib.mkIf hasMonitor {
    services.gvfs.enable = true;
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    home.packages = [ pkgs.pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
