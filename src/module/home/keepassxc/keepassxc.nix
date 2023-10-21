{ pkgs, ... }:

{
  home.packages = with pkgs; [
    keepassxc
  ];

  xdg.configFile."keepassxc/keepassxc.ini".source = ./keepassxc.ini;

  wayland.windowManager.hyprland.extraConfig = ''
    exec-once = keepassxc
  '';
}
