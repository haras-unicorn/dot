{ pkgs, ... }:

let
  desktop = "${pkgs.libsForQt5.okular}/share/applications/okular.desktop";
  mime = {
    "application/pdf" = desktop;
  };
in
{
  home.packages = with pkgs; [
    libsForQt5.okular
  ];

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;
}
