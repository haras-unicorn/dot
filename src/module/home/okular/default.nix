{ pkgs, ... }:

let
  pdf = "${pkgs.libsForQt5.okular}/share/applications/okularApplication_pdf.desktop";
  mime = {
    "application/pdf" = pdf;
  };
in
{
  home.shared = {
    home.packages = with pkgs; [
      libsForQt5.okular
    ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
