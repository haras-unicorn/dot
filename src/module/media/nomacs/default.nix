{ pkgs, ... }:

let
  desktop = "${pkgs.nomacs}/share/applications/nomacs.desktop";
  mime = {
    "image/avif" = desktop;
    "image/bmp" = desktop;
    "image/gif" = desktop;
    "image/vnd.microsoft.icon" = desktop;
    "image/jpeg" = desktop;
    "image/png" = desktop;
    "image/svg+xml" = desktop;
    "image/tiff" = desktop;
    "image/webp" = desktop;
  };
in
{
  home = {
    home.packages = with pkgs; [
      nomacs
    ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
