{ pkgs, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.dot.wallpaper}'"
      ];
    };
  };

  home.shared = {
    services.betterlockscreen.enable = true;
  };
}
