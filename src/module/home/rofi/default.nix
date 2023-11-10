{ pkgs, config, ... }:

# TODO: lulezojne

{
  de.keybinds = [
    {
      mods = [ "super" ];
      key = "return";
      command = "${pkgs.rofi}/bin/rofi -show drun -modi run,drun,window -config '${config.xdg.configHome}/rofi/launcher.rasi'";
    }
    {
      mods = [ "super" ];
      key = "p";
      command = ''${pkgs.keepmenu}/bin/keepmenu'';
    }
    {
      mods = [ "super" "shift" ];
      key = "p";
      command = ''${pkgs.keepmenu}/bin/keepmenu -a "{PASSWORD}"'';
    }
    {
      mods = [ "super" "alt" ];
      key = "p";
      command = ''${pkgs.keepmenu}/bin/keepmenu -a "{TOTP}"'';
    }
  ];

  home.packages = with pkgs; [
    keepmenu
  ];
  xdg.configFile."keepmenu/config.ini".source = ./config.ini;

  programs.rofi.enable = true;
  xdg.configFile."rofi/launcher.rasi".source = ./launcher.rasi;
  xdg.configFile."rofi/colors.rasi".source = ./colors.rasi;
  xdg.configFile."rofi/keepmenu.rasi".source = ./keepmenu.rasi;
}
