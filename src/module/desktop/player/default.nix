{ pkgs, config, lib, ... }:

# TODO: make the volume stuff work (maybe wpctl?)

let
  hasSound = config.dot.hardware.sound.enable;

  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  shared = lib.mkIf (hasSound && hasKeyboard) {
    dot = {
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
        }
        {
          mods = [ "super" "control" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl volume 0.00'';
        }
        {
          mods = [ "super" "control" "shift" ];
          key = "v";
          command = ''${pkgs.playerctl}/bin/playerctl volume 100.00'';
        }
      ];
    };
  };

  home = lib.mkIf hasSound {
    home.packages = [
      pkgs.playerctl
    ];

    services.playerctld.enable = true;
  };
}
