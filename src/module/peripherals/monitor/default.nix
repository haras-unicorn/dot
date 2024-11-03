{ lib, pkgs, config, ... }:

{
  options = {
    dot = {
      screenBrightnessDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "brightnessctl --list";
        default = null;
        example = null;
      };
      keyboardBrightnessDevice = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "brightnessctl --list";
        default = null;
        example = null;
      };
    };
  };

  shared = {
    dot = {
      desktopEnvironment.keybinds = (if !(builtins.isNull config.dot.screenBrightnessDevice) then [
        {
          mods = [ "super" "shift" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.screenBrightnessDevice}' set +2%'';
        }
        {
          mods = [ "super" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.screenBrightnessDevice}' set 2%-'';
        }
      ] else [ ]) ++ (if !(builtins.isNull config.dot.keyboardBrightnessDevice) then [
        {
          mods = [ "super" "control" "shift" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.keyboardBrightnessDevice}' set +2%'';
        }
        {
          mods = [ "super" "control" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.keyboardBrightnessDevice}' set 2%-'';
        }
      ] else [ ]);
    };
  };

  config = {
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
