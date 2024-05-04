{ pkgs, config, ... }:

# TODO: lulezojne

let
  font = ''"${config.dot.font.sans.name}" ${builtins.toString config.dot.font.size.medium}'';

  ini2 = ''
    gtk-font-name = ${font}
    gtk-icon-theme-name = "${config.dot.icon-theme.name}"
    gtk-theme-name = "${config.dot.app-theme.name}"
    gtk-cursor-theme-name = "${config.dot.cursor-theme.name}"
  '';
  ini3 = ''
    [Settings]
    gtk-font-name = ${font}
    gtk-icon-theme-name = ${config.dot.icon-theme.name}
    gtk-theme-name = ${config.dot.app-theme.name}
    gtk-cursor-theme-name = ${config.dot.cursor-theme.name}
  '';
  ini4 = ini3;

  dconf = {
    font-name = font;
    gtk-theme = config.dot.app-theme.name;
    icon-theme = config.dot.icon-theme.name;
    cursor-theme = config.dot.cursor-theme.name;
  };
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

    home.packages = with pkgs; [
      lxappearance
    ];

    xdg.configFile."gtk-2.0/settings.ini".text = ini2;
    xdg.configFile."gtk-3.0/settings.ini".text = ini3;
    xdg.configFile."gtk-4.0/settings.ini".text = ini4;

    dconf.settings."org/gnome/desktop/interface" = dconf;
  };
}
