{ lib, config, pkgs, ... }:

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

  # NOTE: keeping here for reference or in case i want to upstream
  # mkMateriaTheme = colors:
  #   pkgs.materia-theme.overrideAttrs
  #     (old: {
  #       patches = (old.patches or [ ]) ++ [
  #         ./materia-theme-change-color.patch
  #       ];
  #       nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++
  #         (with pkgs; [ bc inkscape optipng ]);
  #       postPatch = (old.postPatch or "") + ''
  #         bg="F5F5F5"
  #         fg="212121"
  #         view="FFFFFF"
  #         surface="FAFAFA"
  #         hdr_bg="455A64"
  #         hdr_fg="FFFFFF"
  #         sel_bg="42A5F5"
  #         args=""
  #         args+="BG=$bg\n"
  #         args+="FG=$fg\n"
  #         args+="MATERIA_VIEW=$view\n"
  #         args+="MATERIA_SURFACE=$surface\n"
  #         args+="HDR_BG=$hdr_bg\n"
  #         args+="HDR_FG=$hdr_fg\n"
  #         args+="SEL_BG=$sel_bg\n"
  #         patchShebangs .
  #         ./change_color.sh <(echo -e "$args")
  #       '';
  #     });
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
            runtimeInputs = with pkgs; [
              stdenvNoCC
              meson
              ninja
              sassc
              gnome.gnome-themes-extra
              gdk-pixbuf
              librsvg
              bc
              inkscape
              optipng 
            ];
            text = ''
              dest="${config.xdg.cacheHome}/materia-theme"
              if [[ -d "$dest" ]]; then
                rm -rf "$dest"
              fi
              cp -r "${pkgs.materia-theme}" "$dest"
              chmod -R 755 "$dest"
              cd "$dest"
              ./change_color.sh \
                -t ${config.homeDirectory}/.themes \
                "${config.xdg.configHome}/materia/colors"
            '';
          }}/bin/change-materia-colors";
          };
        }
      ];
    };
  };
}
