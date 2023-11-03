{ pkgs, ... }:

{
  # TODO: fix not actually typing stuff in
  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, e, exec, ${pkgs.emote}/bin/emote
  '';
}
