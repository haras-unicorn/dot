{ pkgs, config, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${config.dot.wallpaper}'"
      ];
    };
  };

  home = {
    services.betterlockscreen.enable = true;
  };
}
