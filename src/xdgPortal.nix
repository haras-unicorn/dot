{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasMonitor {
    environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];

    programs.dconf.enable = true;
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf hasMonitor {
    desktopEnvironment.sessionVariables = {
      GTK_USE_PORTAL = "1";
    };

    home.packages = [
      pkgs.libnotify
    ];

    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    xdg.portal.config.common.default = "*";
    xdg.portal.extraPortals = lib.optionals hasWayland [
      pkgs.xdg-desktop-portal-hyprland
    ] ++ [
      pkgs.xdg-desktop-portal-gtk
      pkgs.libsForQt5.xdg-desktop-portal-kde
    ];
  };
}
