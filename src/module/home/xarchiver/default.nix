{ pkgs, ... }:

let
  desktop = "${pkgs.xarchiver}/share/applications/xarchiver.desktop";
  mime = {
    "application/x-bzip" = desktop;
    "application/x-bzip2" = desktop;
    "application/gzip" = desktop;
    "application/vnd.rar" = desktop;
    "application/x-tar" = desktop;
    "application/zip" = desktop;
    "application/x-7z-compressed" = desktop;
  };
in
{
  home.shared = {
    home.packages = with pkgs; [
      p7zip
      zip
      unzip
      unrar
      xarchiver
    ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
