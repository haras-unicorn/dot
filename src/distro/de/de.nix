{ self, ... }:

{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/mako/mako.nix"
    "${self}/src/module/home/swww/swww.nix"
    "${self}/src/module/home/eww/eww.nix"
    "${self}/src/module/home/mako/wofi.nix"
  ];
}
