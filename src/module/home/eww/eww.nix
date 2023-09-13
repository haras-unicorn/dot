{ pkgs, hardware, ... }:

# TODO: https://github.com/elkowar/eww/pull/743

{
  programs.eww.enable = true;
  programs.eww.package = pkgs.eww-wayland;
  programs.eww.configDir = ./config;
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.eww-wayland}/bin/eww daemon
  '';
}
