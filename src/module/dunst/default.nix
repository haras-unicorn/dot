{ pkgs, ... }:

# TODO: tint-gear

{
  home.shared = {
    home.packages = with pkgs; [
      libnotify
    ];

    services.dunst.enable = true;
    services.dunst.configFile = ./dunstrc;
  };
}
