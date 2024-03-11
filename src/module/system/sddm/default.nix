{ pkgs, lib, config, sweet-theme, ... }:

with lib;
let
  cfg = config.de;
in
{
  options.de = {
    session = mkOption {
      type = types.str;
      default = [ ];
      example = "none+qtile";
      description = ''
        Session to launch desktop environment.
      '';
    };
  };

  config = {
    environment.systemPackages = with pkgs; [
      libsForQt5.qt5.qtgraphicaleffects # NOTE: for sddm theme
      libsForQt5.plasma-framework # NOTE: for sddm theme
    ];

    services.xserver.displayManager.sddm.enable = true;
    services.xserver.displayManager.sddm.autoNumlock = true;
    services.xserver.displayManager.sddm.theme = "${sweet-theme}/kde/sddm";
    services.xserver.displayManager.defaultSession = "${cfg.session}";
    security.pam.services.sddm.enableGnomeKeyring = true;
  };
}
