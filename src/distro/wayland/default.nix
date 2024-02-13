{ self, ... }:

# TODO: https://github.com/kando-menu/kando

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
    "${self}/src/module/home/swww-lulezojne"
    "${self}/src/module/home/eww"

    "${self}/src/module/home/obs-studio"
    "${self}/src/module/home/grim-slurp-tesseract"
    "${self}/src/module/home/piper"
    "${self}/src/module/home/miraclecast"
    "${self}/src/module/home/gstreamer"

    "${self}/src/module/home/gtk"
    "${self}/src/module/home/qt"

    "${self}/src/module/home/mangohud"
    "${self}/src/module/home/emote"
    "${self}/src/module/home/alarm"

    "${self}/src/module/home/pcmanfm"
    "${self}/src/module/home/spacedrive"
  ];

  # NOTE: needed for tray items to work properly
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}
