{ pkgs, ... }:

let
  mime = {
    "video/mp4" = "${pkgs.vlc}/share/applications/vlc.desktop";
  };
in
{
  home.packages = with pkgs; [ vlc ];

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}
