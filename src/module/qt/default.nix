{ pkgs, ... }:

# NOTE: https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#QGtkStyle

{
  shared = {
    dot = {
      desktopEnvironment.sessionVariables = {
        QT_QPA_PLATFORMTHEME = "gtk2";
      };
    };
  };

  home.shared = {
    home.packages = with pkgs; [
      libsForQt5.qtstyleplugins
      qt6Packages.qt6gtk2
      gnome.gnome-themes-extra
    ];

    xdg.configFile."Trolltech.conf".text = ''
      [Qt]
      style=GTK+    
    '';
  };
}
