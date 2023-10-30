{ pkgs, ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, e, exec, ${pkgs.emote}/bin/emote
  '';
}
