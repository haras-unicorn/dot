{ pkgs, lib, config, user, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  shared = {
    dot = {
      desktopEnvironment.keybinds = lib.mkIf (hasMonitor && hasKeyboard) [
        {
          mods = [ "super" "shift" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl set +2%'';
        }
        {
          mods = [ "super" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl set 2%-'';
        }
      ];
    };
  };

  config = lib.mkIf hasMonitor {
    system = {
      hardware.i2c.enable = true;
      services.ddccontrol.enable = true;

      users.users.${user}.extraGroups = [
        "i2c"
      ];
    };

    home = {
      home.packages = [
        pkgs.brightnessctl
        pkgs.ddcutil # NOTE: because ddccontrol might core dump with nvidia
        pkgs.ddccontrol
        pkgs.ddccontrol-db
      ];
    };
  };
}
