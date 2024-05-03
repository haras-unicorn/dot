{ lib, self, ... }:

# TODO: https://github.com/kando-menu/kando

{
  imports = [
    "${self}/src/module/xdg"

    "${self}/src/module/brightnessctl"
    "${self}/src/module/playerctl"

    "${self}/src/module/hyprland"
    "${self}/src/module/hyprpicker"

    "${self}/src/module/waybar"
    "${self}/src/module/wlogout"
    "${self}/src/module/mako"
    "${self}/src/module/wofi"
    "${self}/src/module/swww-lulezojne"
    "${self}/src/module/eww"

    "${self}/src/module/obs-studio"
    "${self}/src/module/kooha"
    "${self}/src/module/grim-slurp-tesseract"
    "${self}/src/module/miraclecast"
    "${self}/src/module/gstreamer"

    "${self}/src/module/gtk"
    "${self}/src/module/qt"

    "${self}/src/module/mangohud"
    "${self}/src/module/emote"
    "${self}/src/module/alarm"

    "${self}/src/module/pcmanfm"
    # "${self}/src/module/spacedrive"
  ];

  options = {
    dot = {
      mainMonitor = lib.mkOption {
        type = lib.types.str;
        description = ''
          xrandr --query
          hyprctl monitors
          swaymsg -t get_outputs
        '';
        example = "DP-1";
      };
      monitors = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = ''
          xrandr --query
          hyprctl monitors
          swaymsg -t get_outputs
        '';
        example = [ "DP-1" ];
      };
    };
  };

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
