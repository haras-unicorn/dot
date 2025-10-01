{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasMonitor {
    environment.pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    dot.desktopEnvironment.sessionVariables = {
      GTK_USE_PORTAL = "1";
    };

    home.packages = [
      pkgs.libnotify
    ];

    # NOTE: idk why but it solves problems xd
    dot.desktopEnvironment.sessionStartup = [
      "${pkgs.systemd}/bin/systemctl restart --user xdg-desktop-portal*"
    ];

    services.gnome-keyring.enable = true;

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
      pkgs.gnome-keyring
    ];
    xdg.portal.config.common = {
      default = [
        "gtk"
        "kde"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };
  };
}
