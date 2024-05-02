{ pkgs, ... }:

let
  mime = {
    "inode/directory" = "${pkgs.pcmanfm}/share/applications/pcmanfm.desktop";
  };
in
{
  home.shared = {
    home.packages = with pkgs; [ pcmanfm ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
