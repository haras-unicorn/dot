{ pkgs, ... }:

{
  home.packages = with pkgs; [
    keepmenu
  ];
  xdg.configFile."keepmenu/config.ini".source = ./config.ini;

  programs.wofi.enable = true;
  xdg.configFile."wofi/launcher.rasi".source = ./launcher.rasi;
  xdg.configFile."wofi/colors.rasi".source = ./colors.rasi;
  xdg.configFile."wofi/keepmenu.rasi".source = ./keepmenu.rasi;

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, return, exec, wofi --show drun
  '';
}
