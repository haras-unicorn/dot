{ pkgs, ... }:

# NOTE: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/MIME_types/Common_types

let
  desktop = "${pkgs.vlc}/share/applications/vlc.desktop";
  mime = {
    "audio/aac" = desktop;
    "video/x-msvideo" = desktop;
    "audio/mpeg" = desktop;
    "video/mp4" = desktop;
    "video/mpeg" = desktop;
    "audio/ogg" = desktop;
    "video/ogg" = desktop;
    "audio/opus" = desktop;
    "video/mp2t" = desktop;
    "audio/wav" = desktop;
    "audio/webm" = desktop;
    "video/webm" = desktop;
    "video/3gpp" = desktop;
    "audio/3gpp" = desktop;
    "video/3gpp2" = desktop;
    "audio/3gpp2" = desktop;
  };
in
{
  home.shared = {
    home.packages = with pkgs; [ vlc ];

    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;
  };
}
