{ lib, pkgs, self, config, tint-gear, ... }:

# TODO: https://github.com/kando-menu/kando

{
  imports = [
    "${self}/src/module/xdg"

    "${self}/src/module/niri"

    "${self}/src/module/hyprland"
    "${self}/src/module/hyprpicker"

    "${self}/src/module/brightnessctl"
    "${self}/src/module/playerctl"

    "${self}/src/module/tuigreet"
    "${self}/src/module/gtklock"
    "${self}/src/module/wlogout"
    "${self}/src/module/swayidle"

    "${self}/src/module/waybar"
    "${self}/src/module/mako"
    "${self}/src/module/swayosd"
    "${self}/src/module/wofi"
    "${self}/src/module/swww"
    "${self}/src/module/eww"

    "${self}/src/module/obs-studio"
    "${self}/src/module/kooha"
    "${self}/src/module/grim-slurp-tesseract"
    "${self}/src/module/miraclecast"
    "${self}/src/module/gstreamer"
    "${self}/src/module/mangohud"
    "${self}/src/module/screen-pipe"

    "${self}/src/module/gtk"
    "${self}/src/module/qt"

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
      app-theme = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.numix-gtk-theme;
          example = pkgs.sweet;
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "Numix";
          example = "dynamic";
        };
      };
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = pkgs.nixos-artwork.wallpapers.nix-wallpaper-stripes-logo.src;
      };
      colors = lib.mkOption {
        type = with lib.types; (lazyAttrsOf (oneOf [ bool str (listOf str) (lazyAttrsOf str) ]));
        default = builtins.fromJSON ''
          {
            "isLightTheme": false,
            "colors": [
              "#3f4e55",
              "#a25d70",
              "#21291c",
              "#745963",
              "#33212c",
              "#516c8c",
              "#768c81"
            ],
            "bootstrap": {
              "primary": "#e79caf",
              "secondary": "#97a8b0",
              "accent": "#a9c0b5",
              "background": "#13261d",
              "backgroundAlternate": "#3c0019",
              "selection": "#040f15",
              "text": "#af98a5",
              "textAlternate": "#97a191",
              "danger": "#fe8d6c",
              "warning": "#b3f068",
              "info": "#4ee4fe"
            },
            "terminal": {
              "black": "#13261d",
              "white": "#af98a5",
              "brightBlack": "#3c0019",
              "brightWhite": "#97a191",
              "red": "#fe8d6c",
              "green": "#46f292",
              "blue": "#a295fe",
              "yellow": "#b3f068",
              "magenta": "#fe87f6",
              "cyan": "#4ee4fe",
              "brightRed": "#fe8d6c",
              "brightGreen": "#46f292",
              "brightBlue": "#a295fe",
              "brightYellow": "#b3f068",
              "brightMagenta": "#fe87f6",
              "brightCyan": "#4ee4fe"
            }
          }
        '';
      };
    };
  };

  config = {
    shared = {
      dot = {
        colors = tint-gear.lib.colors {
          imagePath = config.dot.wallpaper;
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
        config.dot.app-theme.package
        pkgs.swayimg
      ];
    };
  };
}
