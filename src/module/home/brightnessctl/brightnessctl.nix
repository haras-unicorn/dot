{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, kitty
  '';
}
