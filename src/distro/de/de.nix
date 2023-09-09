{ self, ... }:
{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/dunst/dunst.nix"
  ];
}
