{ pkgs, config, ... }:

# TODO: lulezojne
# TODO: figure out what to do with icon theme in terms of lulezojne
# TODO: cursor theme?

let
  ini2 = ''
    gtk-font-name = "${config.dot.font.sans.name}"
    gtk-icon-theme-name = "BeautyLine"
    gtk-theme-name = "Sweet-Dark"
  '';
  ini3 = ''
    [Settings]
    gtk-font-name=${config.dot.font.sans.name}
    gtk-icon-theme-name=BeautyLine
    gtk-theme-name=Sweet-Dark
  '';
  ini4 = ini3;
in
{
  de.sessionVariables = {
    GTK_USE_PORTAL = 1;
    GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/settings.ini";
  };

  home.packages = [
    pkgs."${config.dot.font.sans.pkg}"
    pkgs.sweet
    pkgs.beauty-line-icon-theme
  ];

  xdg.configFile."gtk-2.0/settings.ini".text = ini2;
  xdg.configFile."gtk-3.0/settings.ini".text = ini3;
  xdg.configFile."gtk-4.0/settings.ini".text = ini4;
}
