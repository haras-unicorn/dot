{ pkgs, ... }:

# TODO: https://github.com/elkowar/eww/pull/743

{
  # TODO: systemd
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.eww-wayland}/bin/eww daemon
  '';

  programs.eww.enable = true;
  programs.eww.package = pkgs.eww-wayland;
  programs.eww.configDir = ./config;
}
