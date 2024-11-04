{ pkgs, ... }:

# TODO: tint-gear

{
  home = {
    home.packages = with pkgs; [
      libnotify
    ];

    services.dunst.enable = true;
    services.dunst.configFile = ./dunstrc;
  };
}
