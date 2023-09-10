{ pkgs, ... }:

{
  home.pacakges = with pkgs; [
    libnotify
  ];

  services.dunst.enable = true;
  services.dunst.configFile = ./dunstrc;
}
