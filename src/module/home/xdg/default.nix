{ pkgs, config, ... }:

{
  home.packages = with pkgs; [
    xdg-user-dirs
    xdg-utils
    shared-mime-info
  ];

  xdg.enable = true;

  xdg.userDirs.enable = true;
  xdg.userDirs.createDirectories = true;

  xdg.desktop = "${config.home.homeDirectory}/desktop";
  xdg.download = "${config.home.homeDirectory}/download";

  xdg.music = "${config.home.homeDirectory}/music";
  xdg.pictures = "${config.home.homeDirectory}/pictures";
  xdg.videos = "${config.home.homeDirectory}/videos";

  xdg.templates = "${config.home.homeDirectory}/templates";
  xdg.documents = "${config.home.homeDirectory}/documents";

  xdg.publicShare = "${config.home.homeDirectory}/public";

  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
}
