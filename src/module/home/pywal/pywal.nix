{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pywal
  ];

  wayland.windowManager.hyprland.extraConfig = ''
  '';
}
