{ pkgs, ... }:

{
  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  de.startup = "${pkgs.hyprland}/bin/Hyprland";
}

