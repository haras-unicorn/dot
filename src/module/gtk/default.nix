{ config, pkgs, ... }:

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
  };

  bootstrap = config.dot.colors.bootstrap;

  preset = pkgs.writeTextFile {
    name = "colors-preset";
    text = ''
      BG=${bootstrap.background.normal.gtk}
      FG=${bootstrap.text.normal.gtk}
      MATERIA_VIEW=${bootstrap.background.normal.gtk}
      MATERIA_SURFACE=${bootstrap.background.normal.gtk}
      HDR_BG=${bootstrap.background.normal.gtk}
      HDR_FG=${bootstrap.text.normal.gtk}
      SEL_BG=${bootstrap.selection.normal.gtk}
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
in
{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = {
        GTK_USE_PORTAL = 1;
      };
    };
  };

  home.shared = {
    dot = {
      desktopEnvironment.sessionVariables = {
        GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/settings.ini";
      };
    };

    xdg.configFile."gtk-2.0/settings.ini".text = ini2;
    xdg.configFile."gtk-3.0/settings.ini".text = ini3;
    xdg.configFile."gtk-4.0/settings.ini".text = ini4;

    dconf.settings."org/gnome/desktop/interface" = dconf;

    home.packages = [ colors ];
  };
}

