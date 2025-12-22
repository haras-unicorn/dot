{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  emote = pkgs.writeShellApplication {
    name = "emote";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.smile
      config.dot.shell.paste
      config.dot.shell.type
    ];
    text = ''
      smile; type "$(paste)"
    '';
  };
in
{
  homeManagerModule = (lib.mkIf (hasMonitor && hasKeyboard)) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "e";
        command = "${emote}/bin/emote";
      }
    ];

    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        arg = "it.mijorus.smile";
      }
    ];

    home.packages = [
      pkgs.smile
      emote
    ];
  };
}
