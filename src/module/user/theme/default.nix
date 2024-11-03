{ config, pkgs, lib, ... }:

let
  theme_name = "colors";

  ini2 = ''
    gtk-font-name = "${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}"
    gtk-icon-theme-name = "${config.dot.icon-theme.name}"
    gtk-cursor-theme-name = "${config.dot.cursor-theme.name}"
    gtk-theme-name = "${theme_name}"
  '';
  ini3 = ''
    [Settings]
    gtk-font-name = ${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}
    gtk-icon-theme-name = ${config.dot.icon-theme.name}
    gtk-cursor-theme-name = ${config.dot.cursor-theme.name}
    gtk-theme-name = "${theme_name}"
  '';
  ini4 = ini3;

  dconf = {
    font-name = "${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}";
    icon-theme = config.dot.icon-theme.name;
    cursor-theme = config.dot.cursor-theme.name;
    cursor-size = config.dot.cursor-theme.size;
    gtk-theme = "${theme_name}";
    color-scheme = if config.dot.colors.isLightTheme then "prefer-light" else "prefer-dark";
  };

  bootstrap = config.dot.colors.bootstrap;
  terminal = config.dot.colors.terminal;

  # NOTE: the theme wants blue actually but i like cyan better :)
  preset = pkgs.writeTextFile {
    name = "colors-preset";
    text = ''
      BG=${bootstrap.background.normal.gtk}
      FG=${bootstrap.text.normal.gtk}
      MATERIA_VIEW=${bootstrap.background.normal.gtk}
      MATERIA_SURFACE=${bootstrap.background.alternate.gtk}
      HDR_BG=${bootstrap.background.normal.gtk}
      HDR_FG=${bootstrap.text.normal.gtk}
      SEL_BG=${bootstrap.selection.normal.gtk}
      INACTIVE_FG=${bootstrap.background.inverted.gtk}
      INACTIVE_MATERIA_VIEW=${bootstrap.text.inverted.gtk}
      MATERIA_COLOR_VARIANT=${if config.dot.colors.isLightTheme then "light" else "dark"}
      TERMINAL_COLOR4=${terminal.cyan.normal.gtk}
      TERMINAL_COLOR5=${terminal.magenta.normal.gtk}
      TERMINAL_COLOR9=${terminal.brightRed.normal.gtk}
      TERMINAL_COLOR10=${terminal.brightGreen.normal.gtk}
      TERMINAL_COLOR11=${terminal.brightYellow.normal.gtk}
      TERMINAL_COLOR12=${terminal.brightCyan.normal.gtk}
    '';
  };

  colors = pkgs.runCommand
    "colors"
    { }
    ''
      cp -r ${pkgs.materia-theme.src}/* .
      find . -type d -exec chmod 755 -- {} +
      find . -type f -exec chmod 644 -- {} +
      find . -type f -name "*.sh" -exec chmod 755 -- {} +

      PATH=$PATH:${pkgs.meson}/bin
      PATH=$PATH:${pkgs.ninja}/bin
      PATH=$PATH:${pkgs.sassc}/bin
      PATH=$PATH:${pkgs.gnome-themes-extra}/bin
      PATH=$PATH:${pkgs.gdk-pixbuf}/bin
      PATH=$PATH:${pkgs.librsvg}/bin
      PATH=$PATH:${pkgs.bc}/bin
      PATH=$PATH:${pkgs.inkscape}/bin
      PATH=$PATH:${pkgs.optipng}/bin

      printf "Patching shebangs...\n"
      patchShebangs .
      printf "\n"

      printf "Changing colors...\n"
      export TMPDIR=$(mktemp -d /tmp/materia-tmp.XXXXXX)      
      ./change_color.sh -t $out/share/themes -o colors ${preset}
      printf "\n"
    '';

  inspect-gtk = pkgs.writeShellApplication {
    name = "inspect-gtk";
    runtimeInputs = [ ];
    text = ''
      export GTK_DEBUG=interactive
      exec "$@"
    '';
  };
in
{
  options = {
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
  };

  shared = {
    dot = {
      desktopEnvironment.sessionVariables = {
        GTK_USE_PORTAL = 1;
        GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/settings.ini";
        QT_QPA_PLATFORMTHEME = "gtk2";
      };

      cursor-theme = { package = pkgs.pokemon-cursor; name = "Pokemon"; };
      icon-theme = { package = pkgs.beauty-line-icon-theme; name = "BeautyLine"; };
    };
  };

  home = {
    xdg.configFile."gtk-2.0/settings.ini".text = ini2;
    xdg.configFile."gtk-3.0/settings.ini".text = ini3;
    xdg.configFile."gtk-4.0/settings.ini".text = ini4;

    dconf.settings."org/gnome/desktop/interface" = dconf;

    home.packages = [
      colors
      inspect-gtk
      pkgs.libsForQt5.qtstyleplugins
      pkgs.qt6Packages.qt6gtk2
      pkgs.gnome-themes-extra
    ];

    home.pointerCursor = {
      package = config.dot.cursor-theme.package;
      name = config.dot.cursor-theme.name;
      size = config.dot.cursor-theme.size;
    };

    xdg.configFile."Trolltech.conf".text = ''
      [Qt]
      style=GTK+    
    '';
  };
}

