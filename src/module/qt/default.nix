{ sweet-theme
, pkgs
, ...
}:

# TODO: font and font size
# TODO: lulezojne
# TODO: icon theme?
# TODO: cursor theme?

{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_STYLE_OVERRIDE = "kvantum";
      };
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      # kde
      libsForQt5.plasma-integration
      libsForQt5.systemsettings

      # kvantum
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
    ];

    xdg.configFile."Kvantum/Sweet".source = "${sweet-theme}/kde/Kvantum/Sweet";
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Sweet
    '';
  };
}
