{
  pkgs,
  config,
  lib,
  ...
}:

# TODO: make the volume stuff work (maybe wpctl?)

let
  hasSound = config.dot.hardware.sound.enable;

  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  homeManagerModule = lib.mkIf hasSound {
    dot.desktopEnvironment.keybinds = lib.mkIf (hasSound && hasKeyboard) [
      {
        mods = [ "super" ];
        key = "v";
        command = ''${pkgs.playerctl}/bin/playerctl play-pause'';
      }
    ];

    home.packages = [
      pkgs.playerctl
    ];

    services.playerctld.enable = true;
  };
}
