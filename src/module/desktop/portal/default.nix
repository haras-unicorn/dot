{ pkgs, lib, config, ... }:

# FIXME: https://github.com/NVIDIA/open-gpu-kernel-modules/issues/467#issuecomment-1544340511

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  system = lib.mkIf hasMonitor {
    environment.pathsToLink = [ "/share/xdg-desktop-portal" "/share/applications" ];
  };

  home = lib.mkIf hasMonitor {
    xdg.portal.enable = true;
    xdg.portal.xdgOpenUsePortal = true;

    xdg.portal.config.common.default = "*";
    xdg.portal.extraPortals = [
      (lib.mkIf hasWayland pkgs.xdg-desktop-portal-hyprland)
      pkgs.xdg-desktop-portal-gtk
      pkgs.libsForQt5.xdg-desktop-portal-kde
    ];

    programs.dconf.enable = true;
  };
}
