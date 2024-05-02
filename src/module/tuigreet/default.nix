{ pkgs, lib, config, ... }:

{
  options.dot.desktopEnvironment = {
    startup = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "Hyprland";
      description = ''
        Command to launch desktop environment.
      '';
    };
  };

  config = {
    system = {
      dot.desktopEnvironment.login =
        "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd ${config.dot.desktopEnvironment.startup}";
    };
  };
}
