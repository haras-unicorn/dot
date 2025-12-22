{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.dot.host.user;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  type = pkgs.writeShellApplication {
    name = "type";
    runtimeInputs = [
      pkgs.ydotool
      pkgs.coreutils
      config.dot.shell.paste
    ];
    text = ''
      printf "%s" "type '$1'" | ydotool
    '';
  };
in
{
  nixosModule = lib.mkIf (hasMonitor && hasKeyboard) {
    programs.ydotool.enable = true;

    users.users.${user}.extraGroups = [
      config.programs.ydotool.group
    ];
  };

  homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard) {
    dot.shell.type = type;
  };
}
