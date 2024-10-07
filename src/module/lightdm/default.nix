{ lib, config, ... }:

let
  cfg = config.dot.desktopEnvironment;
in
{
  options.dot.desktopEnvironment = {
    session = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "qtile";
      description = ''
        Session to launch desktop environment.
      '';
    };
  };

  config = {
    system = {
      services.displayManager.lightdm.enable = true;
      services.displayManager.defaultSession = "${cfg.session}";
      services.displayManager.lighdm.greeters.gtk.enalbe = true;
      security.pam.services.lightdm.enableGnomeKeyring = true;
    };
  };
}
