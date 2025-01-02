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

  system = lib.mkIf hasMonitor {
    services.gvfs.enable = true;
  };

  home = lib.mkIf hasMonitor {
    home.packages = [ pkgs.pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
