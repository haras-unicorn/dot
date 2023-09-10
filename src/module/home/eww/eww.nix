{ pkgs, ... }:

{
  programs.eww.enable = true;
  programs.eww.package = pkgs.eww-wayland;
  programs.eww.configDir = ./config;
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.eww-wayland}/bin/eww daemon

    monitor = DP-1, addreserved, 20, 0, 0, 0, 0
  '';
}
