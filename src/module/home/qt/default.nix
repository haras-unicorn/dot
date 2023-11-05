{ pkgs, sweet-theme, ... }:

# TODO: lulezojne
# TODO: icon theme?
# TODO: cursor theme?

{
  home.packages = with pkgs; [
    libsForQt5.plasma-integration
    libsForQt5.systemsettings
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum
  ];

  de.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    QT_QPA_PLATFORMTHEME = "kde";
    QT_STYLE_OVERRIDE = "kvantum";
  };

  xdg.configFile."Kvantum/Sweet".source = "${sweet-theme}/kde/Kvantum/Sweet";
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Sweet
  '';
}
