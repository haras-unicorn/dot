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

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    xdg.portal.config.common.default = "*";
    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.libsForQt5.xdg-desktop-portal-kde
    ];
  };
}
