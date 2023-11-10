{ pkgs, ... }:

# TODO: lulezojne

{
  home.packages = with pkgs; [
    keepmenu
  ];
  xdg.configFile."keepmenu/config.ini".source = ./config.ini;

  programs.rofi.enable = true;
  xdg.configFile."rofi/launcher.rasi".source = ./launcher.rasi;
  xdg.configFile."rofi/colors.rasi".source = ./colors.rasi;
  xdg.configFile."rofi/keepmenu.rasi".source = ./keepmenu.rasi;
}
