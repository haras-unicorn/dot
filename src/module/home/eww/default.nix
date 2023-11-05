{ pkgs, ... }:

# TODO: use instead of waybar after https://github.com/elkowar/eww/pull/743

{
  de.sessionStartup = [
    "${pkgs.eww-wayland}/bin/eww daemon"
  ];

  programs.eww.enable = true;
  programs.eww.package = pkgs.eww-wayland;
  programs.eww.configDir = ./config;
}
