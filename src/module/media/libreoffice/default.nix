{ pkgs, ... }:

# TODO: colors that libreoffice uses

let
  writer = "${pkgs.libreoffice-fresh}/share/applications/writer.desktop";
  calc = "${pkgs.libreoffice-fresh}/share/applications/calc.desktop";
  impress = "${pkgs.libreoffice-fresh}/share/applications/impress.desktop";
  draw = "${pkgs.libreoffice-fresh}/share/applications/draw.desktop";
  mime = {
    "application/x-abiword" = writer;
    "application/msword" = writer;
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = writer;
    "application/vnd.oasis.opendocument.presentation" = impress;
    "application/vnd.oasis.opendocument.spreadsheet" = calc;
    "application/vnd.oasis.opendocument.text" = writer;
    "application/vnd.ms-powerpoint" = impress;
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = impress;
    "application/rtf" = writer;
    "application/vnd.visio" = draw;
    "text/csv" = calc;
  };
in
{
  home = {
    home.packages = with pkgs; [
      libreoffice-fresh
    ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
