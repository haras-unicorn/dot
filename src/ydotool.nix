{
  config,
  lib,
  pkgs,
  ...
}:

let
  user = config.dot.user;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  pastedo = pkgs.writeShellApplication {
    name = "pastedo";
    runtimeInputs = [
      pkgs.xclip
      pkgs.ydotool
    ];
    text = ''
      echo "type $(${config.dot.shell.paste})" | ydotool
    '';
  };
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard) {
    programs.ydotool.enable = true;

    users.users.${user}.extraGroups = [
      config.programs.ydotool.group
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [
          "ctrl"
          "alt"
        ];
        key = "v";
        command = "${pastedo}/bin/pastedo";
      }
    ];
  };
}
