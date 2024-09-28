{ lib, pkgs, self, config, ... }:

{
  imports = [
    "${self}/src/module/xdg"

    "${self}/src/module/brightnessctl"
    "${self}/src/module/playerctl"

    "${self}/src/module/sddm"
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
          example = "Sweet";
        };
      };
      dark-mode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
      };
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = pkgs.nixos-artwork.wallpapers.nix-wallpaper-stripes-logo.src;
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
        config.dot.app-theme.package
        pkgs.sxiv
      ];
    };
  };
}
