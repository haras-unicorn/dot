{ pkgs, ... }:

# TODO: lulezojne

{
  home.shared = {
    home.packages = with pkgs; [
      libnotify
    ];

    services.dunst.enable = true;
    services.dunst.configFile = ./dunstrc;
  };
}
