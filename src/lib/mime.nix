{
  self.lib.mime = {
    office = [
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

    image = [
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

    audio = [
      "audio/x-matroska"
      "audio/matroska"
      "audio/aac"
      "audio/mpeg"
      "audio/ogg"
      "audio/opus"
      "audio/wav"
      "audio/x-wav"
      "audio/webm"
      "audio/3gpp"
      "audio/3gpp2"
      "audio/flac"
    ];

    video = [
      "video/matroska"
      "video/x-matroska"
      "video/mpeg"
      "video/x-msvideo"
      "video/mp4"
      "video/ogg"
      "video/mp2t"
      "video/webm"
      "video/3gpp"
      "video/3gpp2"
    ];

    archive = [
      "application/x-bzip"
      "application/x-bzip2"
      "application/gzip"
      "application/vnd.rar"
      "application/x-tar"
      "application/zip"
      "application/x-7z-compressed"
    ];

    torrent = [
      "application/x-bittorrent"
    ];

    pdf = [
      "application/pdf"
    ];

    browser = [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];

    editor = [
      "text/css"
      "application/javascript"
      "application/json"
      "application/x-sh"
      "application/xhtml+xml"
      "application/xml"
    ];

    files = [
      "inode/directory"
    ];

    default = {
      audio = "audio/wav";
      video = "video/x-matroska";
      image = "image/png";
      text = "text/plain";
    };

    toolbelt = {
      audio = "audio/x-raw";
    };
  };
}
