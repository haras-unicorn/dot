{ pkgs, ... }:

{
  # TODO: systemd
  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = ${pkgs.alarm-clock-applet}/bin/alarm-clock-applet
  '';

  home.packages = with pkgs; [ alarm-clock-applet ];
} 
