{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brave
  ];

  wayland.windowManager.hyprland.extraConfig = ''
    env = BROWSER, brave

    bind = super, w, exec, brave
  '';
}
