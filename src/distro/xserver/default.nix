{ lib, pkgs, self, config, ... }:

{
  imports = [
    "${self}/src/module/xdg"

    "${self}/src/module/tint-gear"

    "${self}/src/module/brightnessctl"
    "${self}/src/module/playerctl"

    "${self}/src/module/sddm"
    "${self}/src/module/qtile"
    "${self}/src/module/picom"

    "${self}/src/module/polybar"
    "${self}/src/module/dunst"
    "${self}/src/module/rofi"
    "${self}/src/module/redshift"
    "${self}/src/module/feh"
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
      mainMonitorWidth = lib.mkOption {
        type = lib.types.int;
        description = "For configuring the top bar";
        default = 1920;
      };
      mainMonitorDpi = lib.mkOption {
        type = lib.types.int;
        description = ''
          xdpyinfo | grep dots # take average
        '';
        default = 96;
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
      cursor-theme = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.numix-cursor-theme;
          example = pkgs.pokemon-cursor;
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "Numix-Cursor";
          example = "Pokemon";
        };
        size = lib.mkOption {
          type = lib.types.ints.u8;
          default = 32;
          example = 24;
        };
      };
      icon-theme = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.numix-icon-theme;
          example = pkgs.beauty-line-icon-theme;
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "Numix";
          example = "BeautyLine";
        };
      };
      opacity = lib.mkOption {
        type = lib.types.float;
        default = 0.8;
        example = 0.9;
      };
    };
  };

  config = {
    home.shared = {
      # NOTE: needed for tray items to work properly
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      home.pointerCursor = {
        package = config.dot.cursor-theme.package;
        name = config.dot.cursor-theme.name;
        size = config.dot.cursor-theme.size;
      };


      dconf.settings."org/gnome/desktop/interface".color-scheme =
        lib.mkMerge [
          (lib.mkIf config.dot.colors.isLightTheme "prefer-light")
          (lib.mkIf (!config.dot.colors.isLightTheme) "prefer-dark")
        ];

      home.packages = [
        config.dot.cursor-theme.package
        config.dot.icon-theme.package
        pkgs.sxiv
      ];
    };
  };
}
