{ pkgs, ... }:

# FIXME: https://github.com/hyprwm/hyprpicker/issues/51

{
  home.shared = {
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
  };
}
