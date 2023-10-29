{ self, ... }:

{
  imports = [
    "${self}/src/module/home/xdg/xdg.nix"

    "${self}/src/module/home/brightnessctl/brightnessctl.nix"
    "${self}/src/module/home/playerctl/playerctl.nix"

    "${self}/src/module/home/hyprland/hyprland.nix"

    "${self}/src/module/home/waybar/waybar.nix"
    "${self}/src/module/home/wlogout/wlogout.nix"
    "${self}/src/module/home/mako/mako.nix"
    "${self}/src/module/home/wofi/wofi.nix"
    "${self}/src/module/home/wallpaper/wallpaper.nix"
    "${self}/src/module/home/eww/eww.nix"

    "${self}/src/module/home/obs-studio/obs-studio.nix"
    "${self}/src/module/home/grim/grim.nix"
    "${self}/src/module/home/miraclecast/miraclecast.nix"

    "${self}/src/module/home/gtk/gtk.nix"
    "${self}/src/module/home/qt/qt.nix"

    "${self}/src/module/home/emote/emote.nix"
  ];

  # NOTE: needed for tray items to work properly
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}
