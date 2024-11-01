{ pkgs, ... }:

# FIXME: https://github.com/hyprwm/hyprpicker/issues/51

{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "c";
          command = "${pkgs.hyprpicker}/bin/hyprpicker";
        }
      ];
    };
  };

  home = {
    home.packages = [
      pkgs.hyprpicker
    ];
  };
}
