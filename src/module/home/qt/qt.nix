{ pkgs, ... }:

{
  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Sweet-Dark";
  qt.style.package = pkgs.sweet;
  wayland.windowManager.hyprland.extraConfig = ''env = QT_QPA_PLATFORM,wayland'';
}
