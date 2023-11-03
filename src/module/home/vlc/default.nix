{ pkgs, ... }:

{
  home.packages = with pkgs; [ vlc ];

  xdg.mimeApps.associations.added = {
    "video/mp4" = "${pkgs.vlc}/share/applications/vlc.desktop";
  };
}
