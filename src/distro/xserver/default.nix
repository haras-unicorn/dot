{ self, ... }:

{
  imports = [
    "${self}/src/module/home/xdg"

    "${self}/src/module/home/brightnessctl"
    "${self}/src/module/home/playerctl"

    "${self}/src/module/home/qtile"

    "${self}/src/module/home/dunst"
    "${self}/src/module/home/rofi"
    "${self}/src/module/home/redshift"
    "${self}/src/module/home/feh-lulezojne"
    "${self}/src/module/home/betterlockscreen"

    "${self}/src/module/home/obs-studio"
    "${self}/src/module/home/peek"
    "${self}/src/module/home/flameshot"
    "${self}/src/module/home/piper"
    "${self}/src/module/home/miraclecast"
    "${self}/src/module/home/gstreamer"

    "${self}/src/module/home/gtk"
    "${self}/src/module/home/qt"

    "${self}/src/module/home/mangohud"
    "${self}/src/module/home/emote"
    "${self}/src/module/home/alarm"

    "${self}/src/module/home/pcmanfm"
    # "${self}/src/module/home/spacedrive"
  ];

  # NOTE: needed for tray items to work properly
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = [ "graphical-session-pre.target" ];
    };
  };
}
