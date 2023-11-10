{ pkgs, config, ... }:

# TODO: shift keyboard brightness and non shift monitor brightness

{
  de.keybinds = (if !(builtins.isNull config.dot.hardware.screenBrightnessDevice) then [
    {
      mods = [ ];
      key = "XF86MonBrightnessUp";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.screenBrightnessDevice}' set +2%'';
    }
    {
      mods = [ ];
      key = "XF86MonBrightnessDown";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.screenBrightnessDevice}' set 2%-'';
    }
  ] else [ ]) ++ (if !(builtins.isNull config.dot.hardware.keyboardBrightnessDevice) then [
    {
      mods = [ "shift" ];
      key = "XF86MonBrightnessUp";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.keyboardBrightnessDevice}' set +2%'';
    }
    {
      mods = [ "shift" ];
      key = "XF86MonBrightnessDown";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='${config.dot.hardware.keyboardBrightnessDevice}' set 2%-'';
    }
  ] else [ ]);

  home.packages = with pkgs; [ brightnessctl ];
}
