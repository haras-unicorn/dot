{ lib, pkgs, self, config, ... }:

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
    "${self}/src/module/swww-lulezojne"
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
      dark-mode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
      };
      wallpaper = lib.mkOption {
        type = lib.types.string;
        default = pkgs.nixos-artwork.wallpapers.nix-wallpaper-stripes-logo.src;
        example = "dynamic";
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
      lib.mkIf config.dot.dark-mode "prefer-dark";

    home.packages = [
      config.dot.cursor-theme.package
      config.dot.icon-theme.package
      config.dot.app-theme.package
      pkgs.swayimg
    ];
  };
}
