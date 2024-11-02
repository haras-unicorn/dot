{ pkgs, config, ... }:

let
  visual = { package = pkgs.vscode; bin = "code"; };
  browser = { package = pkgs.firefox-bin; bin = "firefox"; };

  browserDesktop = "${browser.package}/share/applications/${browser.bin}.desktop";
  browserMime = {
    "text/html" = browserDesktop;
    "x-scheme-handler/http" = browserDesktop;
    "x-scheme-handler/https" = browserDesktop;
  };

  visualDesktop = "${visual.package}/share/applications/${visual.bin}.desktop";
  visualMime = {
    "text/css" = visualDesktop;
    "application/javascript" = visualDesktop;
    "application/json" = visualDesktop;
    "application/x-sh" = visualDesktop;
    "application/xhtml+xml" = visualDesktop;
    "application/xml" = visualDesktop;
  };

  mime = browserMime // visualMime;
in
{
  home = {
    xdg.mimeApps.associations.added = mime;
    xdg.mimeApps.defaultApplications = mime;

    home.packages = with pkgs; [
      xdg-user-dirs
      xdg-utils
      shared-mime-info
    ];

    xdg.enable = true;

    xdg.userDirs.enable = true;
    xdg.userDirs.createDirectories = true;

    xdg.userDirs.desktop = "${config.home.homeDirectory}/desktop";
    xdg.userDirs.download = "${config.home.homeDirectory}/download";

    xdg.userDirs.music = "${config.home.homeDirectory}/music";
    xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
    xdg.userDirs.videos = "${config.home.homeDirectory}/videos";

    xdg.userDirs.templates = "${config.home.homeDirectory}/templates";
    xdg.userDirs.documents = "${config.home.homeDirectory}/documents";

    xdg.userDirs.publicShare = "${config.home.homeDirectory}/public";

    xdg.mime.enable = true;
    xdg.mimeApps.enable = true;
  };
}
