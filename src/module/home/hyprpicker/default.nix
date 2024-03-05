{ pkgs, ... }:
{
  home.packages = [
    pkgs.hyprpicker
  ];


  de.keybinds = [
    {
      mods = [ "super" ];
      key = "c";
      command = "${pkgs.hyprpicker}/bin/hyprpicker";
    }
  ];
}
