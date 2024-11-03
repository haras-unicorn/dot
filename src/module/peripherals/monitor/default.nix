{ pkgs, lib, config, ... }:

{
  shared = lib.mkIf config.dot.hardware.monitor.enable {
    dot = {
      desktopEnvironment.keybinds = [
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

  config = lib.mkIf config.dot.hardware.monitor.enable {
    system = {
      hardware.i2c.enable = true;
      services.ddccontrol.enable = true;
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
