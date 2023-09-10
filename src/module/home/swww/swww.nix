{ pkgs, ... }:

{
  home.packages = with pkgs; [
    swww
  ];
  wayland.windowManager.hyprland.extraConfig = ''exec-once = ${pkgs.swww} init'';
}
