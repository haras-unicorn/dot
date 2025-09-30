{
  pkgs,
  lib,
  config,
  ...
}:

# TODO: colors that libreoffice uses
# TODO: transmission mime
# NOTE: transmission peer port is 51413

let
  writer = "${pkgs.libreoffice-fresh}/share/applications/writer.desktop";
  calc = "${pkgs.libreoffice-fresh}/share/applications/calc.desktop";
  impress = "${pkgs.libreoffice-fresh}/share/applications/impress.desktop";
  draw = "${pkgs.libreoffice-fresh}/share/applications/draw.desktop";

  nomacs = "${pkgs.nomacs}/share/applications/nomacs.desktop";

  okular = "${pkgs.libsForQt5.okular}/share/applications/okularApplication_pdf.desktop";

  vlc = "${pkgs.vlc}/share/applications/vlc.desktop";

  xarchiver = "${pkgs.xarchiver}/share/applications/xarchiver.desktop";

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

    "image/avif" = nomacs;
    "image/bmp" = nomacs;
    "image/gif" = nomacs;
    "image/vnd.microsoft.icon" = nomacs;
    "image/jpeg" = nomacs;
    "image/png" = nomacs;
    "image/svg+xml" = nomacs;
    "image/tiff" = nomacs;
    "image/webp" = nomacs;

    "application/pdf" = okular;

    "audio/aac" = vlc;
    "video/x-msvideo" = vlc;
    "audio/mpeg" = vlc;
    "video/mp4" = vlc;
    "video/mpeg" = vlc;
    "audio/ogg" = vlc;
    "video/ogg" = vlc;
    "audio/opus" = vlc;
    "video/mp2t" = vlc;
    "audio/wav" = vlc;
    "audio/webm" = vlc;
    "video/webm" = vlc;
    "video/3gpp" = vlc;
    "audio/3gpp" = vlc;
    "video/3gpp2" = vlc;
    "audio/3gpp2" = vlc;

    "application/x-bzip" = xarchiver;
    "application/x-bzip2" = xarchiver;
    "application/gzip" = xarchiver;
    "application/vnd.rar" = xarchiver;
    "application/x-tar" = xarchiver;
    "application/zip" = xarchiver;
    "application/x-7z-compressed" = xarchiver;
  };
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf config.dot.hardware.monitor.enable {
    home.packages = [
      pkgs.libreoffice-fresh
      pkgs.nomacs
      pkgs.libsForQt5.okular
      pkgs.vlc
      pkgs.xarchiver
      pkgs.transmission_4-gtk
      pkgs.pinta
      pkgs.gimp
      pkgs.mpv
      pkgs.shotcut
      pkgs.video-downloader
    ];

    xdg.mime.enable = true;
    xdg.mimeApps.enable = true;
    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
