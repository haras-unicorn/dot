{ pkgs, ... }:

{
  # TODO: bind
  wayland.windowManager.hyprland.extraConfig = ''
  '';

  home.packages = with pkgs; [
    brightnessctl
  ];
}
