{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/dunst/dunst.nix"
  ];

  home.packages = with pkgs; [
    waybar
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];
}
