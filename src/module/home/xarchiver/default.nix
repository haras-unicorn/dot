{ pkgs, ... }:

let
  desktop = "${pkgs.xarchiver}/share/applications/xarchiver.desktop";
  mime = {
    "inode/directory" = desktop;
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
  home.packages = with pkgs; [
    p7zip
    zip
    unzip
    rar
    unrar
    xarchiver
  ];

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}
