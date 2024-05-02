{ self, pkgs, ... }:

{
  home.shared = {
    de.sessionStartup = [
      "${pkgs.betterlockscreen}/bin/betterlockscreen --update '${self}/assets/greeter.png'"
    ];

    services.betterlockscreen.enable = true;
  };
}
