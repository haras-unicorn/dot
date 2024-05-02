{ self, ... }:

{
  imports = [
    "${self}/src/module/xdg"

    "${self}/src/module/brightnessctl"
    "${self}/src/module/playerctl"

    "${self}/src/module/qtile"

    "${self}/src/module/dunst"
    "${self}/src/module/rofi"
    "${self}/src/module/redshift"
    "${self}/src/module/feh-lulezojne"
    "${self}/src/module/betterlockscreen"

    "${self}/src/module/obs-studio"
    "${self}/src/module/peek"
    "${self}/src/module/flameshot"
    "${self}/src/module/miraclecast"
    "${self}/src/module/gstreamer"

    "${self}/src/module/gtk"
    "${self}/src/module/qt"

    "${self}/src/module/mangohud"
    "${self}/src/module/emote"
    "${self}/src/module/alarm"

    "${self}/src/module/pcmanfm"
    "${self}/src/module/spacedrive"
  ];

  home.shared = {
    # NOTE: needed for tray items to work properly
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
