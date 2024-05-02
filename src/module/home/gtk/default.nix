{ pkgs, config, ... }:

# TODO: lulezojne
# TODO: figure out what to do with icon theme in terms of lulezojne
# TODO: cursor theme?

let
  font = ''"${config.dot.font.sans.name}" ${builtins.toString config.dot.font.size.medium}'';
  ini2 = ''
    gtk-font-name = ${font}
    gtk-icon-theme-name = "BeautyLine"
    gtk-theme-name = "Sweet-Dark"
  '';
  ini3 = ''
    [Settings]
    gtk-font-name = ${font}
    gtk-icon-theme-name = BeautyLine
    gtk-theme-name = Sweet-Dark
  '';
  ini4 = ini3;

  dconf = {
    font-name = font;
    gtk-theme = "Sweet-Dark";
    icon-theme = "BeautyLine";
  };
in
{
  home.shared = {
    de.sessionVariables = {
      GTK_USE_PORTAL = 1;
      GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/settings.ini";
    };

    home.packages = with pkgs; [
      lxappearance
      pkgs."${config.dot.font.sans.pkg}"
      sweet
      beauty-line-icon-theme
    ];

    xdg.configFile."gtk-2.0/settings.ini".text = ini2;
    xdg.configFile."gtk-3.0/settings.ini".text = ini3;
    xdg.configFile."gtk-4.0/settings.ini".text = ini4;

    dconf.settings."org/gnome/desktop/interface" = dconf;
  };
}
