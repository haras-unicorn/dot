{ self, pkgs, ... }:

{
  shared = {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${self}/assets/greeter.png'"
      ];
    };
  };

  home.shared = {
    services.betterlockscreen.enable = true;
  };
}
