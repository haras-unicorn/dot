{ pkgs, lib, config, ... }:

let
  cfg = config.dot.desktopEnvironment;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  options.desktopEnvironment = {
    session = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "qtile";
      description = ''
        Session to launch desktop environment.
      '';
    };
  };

  config = lib.mkIf (hasMonitor && hasKeyboard && !hasWayland) {
    system = {
      environment.systemPackages = with pkgs; [
        libsForQt5.qt5.qtgraphicaleffects # NOTE: for sddm theme
        libsForQt5.plasma-framework # NOTE: for sddm theme
      ];

      services.displayManager.sddm.enable = true;
      services.displayManager.sddm.autoNumlock = true;
      services.displayManager.sddm.theme = "${pkgs.sweet-nova.src}/kde/sddm";
      services.displayManager.defaultSession = "${cfg.session}";
      security.pam.services.sddm.enableGnomeKeyring = true;
    };
  };
}
