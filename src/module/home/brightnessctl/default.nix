{ pkgs, ... }:

# TODO: shift keyboard brightness and non shift monitor brightness

{
  de.keybinds = [
    {
      mods = [ ];
      key = "XF86MonBrightnessUp";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='TODO' set +2%'';
    }
    {
      mods = [ ];
      key = "XF86MonBrightnessDown";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='TODO' set 2%-'';
    }
    {
      mods = [ "shift" ];
      key = "XF86MonBrightnessUp";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='TODO' set +2%'';
    }
    {
      mods = [ "shift" ];
      key = "XF86MonBrightnessDown";
      command = ''${pkgs.brightnessctl}/bin/brightnessctl --device='TODO' set 2%-'';
    }
  ];

  home.packages = with pkgs; [ brightnessctl ];
}
