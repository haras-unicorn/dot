{ self, ... }:

{
  imports = [
    "${self}/src/module/home/xdg"

    "${self}/src/module/home/brightnessctl"
    "${self}/src/module/home/playerctl"

    "${self}/src/module/home/hyprland"

    "${self}/src/module/home/waybar"
    "${self}/src/module/home/wlogout"
    "${self}/src/module/home/mako"
    "${self}/src/module/home/wofi"
    "${self}/src/module/home/wallpaper"
    "${self}/src/module/home/eww"

    "${self}/src/module/home/obs-studio"
    "${self}/src/module/home/grim"
    "${self}/src/module/home/miraclecast"

    "${self}/src/module/home/gtk"
    "${self}/src/module/home/qt"

    # TODO: use when more stable and faster
    # "${self}/src/module/home/spacedrive"
    "${self}/src/module/home/pcmanfm"

    "${self}/src/module/home/mangohud"
  ];

  # NOTE: needed for tray items to work properly
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}
