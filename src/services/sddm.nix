{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.dot.desktopEnvironment;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  nixosModule = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    environment.systemPackages = [
      pkgs.libsForQt5.qt5.qtgraphicaleffects
      pkgs.libsForQt5.plasma-framework
    ];

    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.autoNumlock = true;
    services.displayManager.sddm.theme = "${pkgs.sweet-nova.src}/kde/sddm";
    services.displayManager.defaultSession = "${cfg.startup}";
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
