{ lib, config, pkgs, materia-theme, ... }:

let
  mkIfElse = (p: yes: no: lib.mkMerge [
    (lib.mkIf p yes)
    (lib.mkIf (!p) no)
  ]);

  withAppThemeName = x:
    mkIfElse
      (config.dot.app-theme.name == "dynamic")
      (mkIfElse config.dot.dark-mode
        (x "Materia-dark")
        (x "Materia-light"))
      (x config.dot.app-theme.name);

  ini2 = withAppThemeName (appThemeName: ''
    gtk-font-name = "${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}"
    gtk-icon-theme-name = "${config.dot.icon-theme.name}"
    gtk-cursor-theme-name = "${config.dot.cursor-theme.name}"
    gtk-theme-name = "${appThemeName}"
  '');
  ini3 = withAppThemeName (appThemeName: ''
    [Settings]
    gtk-font-name = ${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}
    gtk-icon-theme-name = ${config.dot.icon-theme.name}
    gtk-cursor-theme-name = ${config.dot.cursor-theme.name}
    gtk-theme-name = ${appThemeName}
  '');
  ini4 = ini3;

  dconf = withAppThemeName (appThemeName: {
    font-name = "${config.dot.font.sans.name} ${builtins.toString config.dot.font.size.medium}";
    icon-theme = config.dot.icon-theme.name;
    cursor-theme = config.dot.cursor-theme.name;
    cursor-size = config.dot.cursor-theme.size;
    gtk-theme = appThemeName;
  });
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

    programs.lulezojne.config = {
      plop = [
        {
          template = ''
            BG={{ vivid ansi.main.black }}
            FG={{ vivid ansi.main.white }}
            MATERIA_VIEW={{ vivid ansi.main.white }}
            MATERIA_SURFACE={{ vivid ansi.main.white }}
            HDR_BG={{ vivid ansi.main.black }}
            HDR_FG={{ vivid ansi.main.white }}
            SEL_BG={{ vivid ansi.main.red }}
          '';
          "in" = "${config.xdg.configHome}/materia/colors";
          "then" = {
            command = "${pkgs.writeShellApplication {
            name = "change-materia-colors";
            runtimeInputs = with pkgs; [ bc inkscape optipng ];
            text = ''
              dest="${config.xdg.cacheHome}/materia-theme"
              if [[ -d "$dest" ]]; then
                rm -rf "$dest"
              fi
              cp -r "${materia-theme}" "$dest"
              cd "$dest"
              ./change_color.sh "${config.xdg.configHome}/materia/colors"
            '';
          }}/bin/change-materia-colors";
          };
        }
      ];
    };
  };
}
