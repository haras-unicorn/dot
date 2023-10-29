{ pkgs, sweet-theme, ... }:

# TODO: lulezojne

{
  home.packages = with pkgs; [
    lxappearance
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_STYLE_OVERRIDE = "kvantum";
  };

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
}
