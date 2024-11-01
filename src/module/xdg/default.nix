{ pkgs, config, ... }:

{
  home = {
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
