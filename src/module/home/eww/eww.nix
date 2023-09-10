{ pkgs, hardware, ... }:

{
  programs.eww.enable = true;
  programs.eww.package = pkgs.eww-wayland;
  programs.eww.configDir = ./config;
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.eww-wayland}/bin/eww daemon
    exec-once = ${pkgs.eww-wayland}/bin/eww open top-bar

    monitor = ${hardware.mainMonitor}, addreserved, 32, 0, 0, 0, 0
  '';
}
