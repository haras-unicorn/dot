{ pkgs, ... }:

# TODO: make the volume stuff work (maybe wpctl?)

{
  shared = {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
        }
        {
          mods = [ "super" "alt" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl volume 0.00'';
        }
        {
          mods = [ "super" "control" "shift" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 +'';
        }
        {
          mods = [ "super" "control" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl volume 0.05 -'';
        }
      ];
    };
  };

  home.shared = {
    services.playerctld.enable = true;
  };
}
