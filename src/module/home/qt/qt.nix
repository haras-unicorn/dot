{ sweet-theme, ... }:

{
  qt.enable = true;
  qt.platformTheme = "kde";
  qt.style.name = "kvantum";
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
