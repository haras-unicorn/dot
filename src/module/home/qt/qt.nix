{ pkgs, sweet-theme, ... }:

# TODO: try minimize but be careful cuz its really brittle

{
  qt.enable = true;
  qt.platformTheme = "kde";
  qt.style.name = "kvantum";
  qt.style.package = with pkgs; [
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];
  xdg.configFile."Kvantum/Sweet".source = "${sweet-theme}/kde/Kvantum/Sweet";
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Sweet
  '';

  wayland.windowManager.hyprland.extraConfig = ''
    env = QT_QPA_PLATFORM,wayland
    env = QT_STYLE_OVERRIDE,kvantum
  '';
}
