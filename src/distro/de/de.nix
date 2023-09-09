{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/dunst/dunst.nix"
  ];

  home.packages = with pkgs; [
    waybar
    swww
  ];
}
