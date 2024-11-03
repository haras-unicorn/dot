{ pkgs, ... }:

let
  mime = {
    "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
  };
in
{
  shared.dot = {
    desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "pcmanfm";
      xarg = "pcmanfm";
    }];
  };

  home = {
    home.packages = with pkgs; [ pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
