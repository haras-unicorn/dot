# TODO: colors that libreoffice uses
# TODO: transmission mime
# NOTE: transmission peer port is 51413

{
  machines.homeModules.media =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      libreoffice = pkgs.libreoffice-fresh;

      writer = "dot-writer.desktop";
      calc = "dot-calc.desktop";
      impress = "dot-impress.desktop";
      draw = "dot-draw.desktop";
      nomacs = "dot-nomacs.desktop";
      okular = "dot-okular.desktop";
      vlc = "dot-vlc.desktop";
      xarchiver = "dot-xarchiver.desktop";

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
    lib.mkIf hardware.interface {
      home.packages = [
        libreoffice
        pkgs.nomacs
        pkgs.kdePackages.okular
        pkgs.vlc
        pkgs.xarchiver
        pkgs.transmission_4-gtk
        pkgs.pinta
        pkgs.gimp
        pkgs.mpv
        pkgs.shotcut
        pkgs.video-downloader
        pkgs.gnome-maps
      ];

      xdg.desktopEntries = {
        dot-writer = {
          name = "LibreOffice Writer";
          exec = "${lib.getExe libreoffice} --writer %U";
          terminal = false;
          mimeType = [
            "application/x-abiword"
            "application/msword"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.oasis.opendocument.text"
            "application/rtf"
          ];
          noDisplay = true;
        };
        dot-calc = {
          name = "LibreOffice Calc";
          exec = "${lib.getExe libreoffice} --calc %U";
          terminal = false;
          mimeType = [
            "application/vnd.oasis.opendocument.spreadsheet"
            "text/csv"
          ];
          noDisplay = true;
        };
        dot-impress = {
          name = "LibreOffice Impress";
          exec = "${lib.getExe libreoffice} --impress %U";
          terminal = false;
          mimeType = [
            "application/vnd.oasis.opendocument.presentation"
            "application/vnd.ms-powerpoint"
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
          ];
          noDisplay = true;
        };
        dot-draw = {
          name = "LibreOffice Draw";
          exec = "${lib.getExe libreoffice} --draw %U";
          terminal = false;
          mimeType = [
            "application/vnd.visio"
          ];
          noDisplay = true;
        };
        dot-nomacs = {
          name = "Nomacs";
          exec = "${lib.getExe pkgs.nomacs} %U";
          terminal = false;
          mimeType = [
            "image/avif"
            "image/bmp"
            "image/gif"
            "image/vnd.microsoft.icon"
            "image/jpeg"
            "image/png"
            "image/svg+xml"
            "image/tiff"
            "image/webp"
          ];
          noDisplay = true;
        };
        dot-okular = {
          name = "Okular";
          exec = "${lib.getExe pkgs.kdePackages.okular} %U";
          terminal = false;
          mimeType = [
            "application/pdf"
          ];
          noDisplay = true;
        };
        dot-vlc = {
          name = "VLC";
          exec = "${lib.getExe pkgs.vlc} %U";
          terminal = false;
          mimeType = [
            "audio/aac"
            "video/x-msvideo"
            "audio/mpeg"
            "video/mp4"
            "video/mpeg"
            "audio/ogg"
            "video/ogg"
            "audio/opus"
            "video/mp2t"
            "audio/wav"
            "audio/webm"
            "video/webm"
            "video/3gpp"
            "audio/3gpp"
            "video/3gpp2"
            "audio/3gpp2"
          ];
          noDisplay = true;
        };
        dot-xarchiver = {
          name = "XArchiver";
          exec = "${lib.getExe pkgs.xarchiver} %U";
          terminal = false;
          mimeType = [
            "application/x-bzip"
            "application/x-bzip2"
            "application/gzip"
            "application/vnd.rar"
            "application/x-tar"
            "application/zip"
            "application/x-7z-compressed"
          ];
          noDisplay = true;
        };
      };

      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;
    };
}
