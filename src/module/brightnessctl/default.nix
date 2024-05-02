{ lib, pkgs, config, ... }:

# TODO: subkey
# TODO: mkIf and all that

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

  config = {
    home.shared = {
      de.keybinds = (if !(builtins.isNull config.dot.hardware.screenBrightnessDevice) then [
        {
          mods = [ "super" "shift" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.screenBrightnessDevice}' set +2%'';
        }
        {
          mods = [ "super" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.screenBrightnessDevice}' set 2%-'';
        }
      ] else [ ]) ++ (if !(builtins.isNull config.dot.hardware.keyboardBrightnessDevice) then [
        {
          mods = [ "super" "control" "shift" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.keyboardBrightnessDevice}' set +2%'';
        }
        {
          mods = [ "super" "control" ];
          key = "b";
          command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.keyboardBrightnessDevice}' set 2%-'';
        }
      ] else [ ]);

      home.packages = with pkgs; [ brightnessctl ];
    };
  };
}
