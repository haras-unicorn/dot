{ self, ... }:

{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/dunst/dunst.nix"
    "${self}/src/module/home/wofi/wofi.nix"
    "${self}/src/module/home/swww/swww.nix"
    "${self}/src/module/home/eww/eww.nix"
  ];
}
