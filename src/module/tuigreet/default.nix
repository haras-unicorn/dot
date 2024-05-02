{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.de;
in
{
  options.de = {
    startup = mkOption {
      type = types.str;
      default = [ ];
      example = "Hyprland";
      description = ''
        Command to launch desktop environment.
      '';
    };
  };

  config = {
    system = {
      de.login = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${cfg.startup}";
    };
  };
}
