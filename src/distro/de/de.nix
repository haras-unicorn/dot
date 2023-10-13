{ self, ... }:

{
  imports = [
    "${self}/src/module/home/hyprland/hyprland.nix"
    "${self}/src/module/home/waybar/waybar.nix"
    "${self}/src/module/home/wlogout/wlogout.nix"
    "${self}/src/module/home/mako/mako.nix"
    "${self}/src/module/home/wofi/wofi.nix"
    "${self}/src/module/home/wallpaper/wallpaper.nix"
    "${self}/src/module/home/eww/eww.nix"
    "${self}/src/module/home/obs-studio/obs-studio.nix"
    "${self}/src/module/home/grim/grim.nix"
    "${self}/src/module/home/brightnessctl/brightnessctl.nix"
    "${self}/src/module/home/playerctl/playerctl.nix"
  ];
}
