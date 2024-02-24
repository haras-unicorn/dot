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
    environment.systemPackages = with pkgs; [
      tuigreet
    ];

    de.login = "${pkgs.tuigreet}/bin/tuigreet --cmd ${cfg.startup}";
  };
}
