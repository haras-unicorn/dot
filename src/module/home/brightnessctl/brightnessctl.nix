{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
  ];

  wayland.windowManager.hyprland.extraConfig = ''
  '';
}
