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
    in
    lib.mkIf hardware.browser {
      dot.mime.apps = [
        {
          package = pkgs.transmission_4-gtk;
          types = [
            "application/x-bittorrent"
          ];
        }
        {
          package = pkgs.libreoffice-fresh;
          types = [
            "application/x-abiword"
            "application/msword"
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            "application/vnd.oasis.opendocument.presentation"
            "application/vnd.oasis.opendocument.spreadsheet"
            "application/vnd.oasis.opendocument.text"
            "application/vnd.ms-powerpoint"
            "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            "application/rtf"
            "application/vnd.visio"
            "text/csv"
          ];
        }
        {
          package = pkgs.loupe;
          types = [
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
        }
        {
          package = pkgs.kdePackages.okular;
          types = [ "application/pdf" ];
        }
        {
          package = pkgs.vlc;
          types = [
            "audio/aac"
            "audio/mpeg"
            "audio/ogg"
            "audio/opus"
            "audio/wav"
            "audio/x-wav"
            "audio/webm"
            "audio/3gpp"
            "audio/3gpp2"

            "video/mpeg"
            "video/x-msvideo"
            "video/mp4"
            "video/ogg"
            "video/mp2t"
            "video/webm"
            "video/3gpp"
            "video/3gpp2"
          ];
        }
        {
          package = pkgs.xarchiver;
          types = [
            "application/x-bzip"
            "application/x-bzip2"
            "application/gzip"
            "application/vnd.rar"
            "application/x-tar"
            "application/zip"
            "application/x-7z-compressed"
          ];
        }
      ];
    };
}
