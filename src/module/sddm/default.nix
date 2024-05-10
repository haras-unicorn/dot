{ pkgs, lib, config, ... }:

let
  cfg = config.de;
in
{
  options.de = {
    session = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "none+qtile";
      description = ''
        Session to launch desktop environment.
      '';
    };
  };

  config = {
    system = {
      environment.systemPackages = with pkgs; [
        libsForQt5.qt5.qtgraphicaleffects # NOTE: for sddm theme
        libsForQt5.plasma-framework # NOTE: for sddm theme
      ];

      services.xserver.displayManager.sddm.enable = true;
      services.xserver.displayManager.sddm.autoNumlock = true;
      services.xserver.displayManager.sddm.theme = "${pkgs.sweet-nova.src}/kde/sddm";
      services.xserver.displayManager.defaultSession = "${cfg.session}";
      security.pam.services.sddm.enableGnomeKeyring = true;
    };
  };
}
