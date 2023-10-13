{ pkgs, ... }:

{
  programs.kitty.enable = true;
  programs.kitty.extraConfig = builtins.readFile ./kitty.conf;

  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty
  '';
}
