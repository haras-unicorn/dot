{ lib, ... }:

{
  options.desktopEnvironment = {
    startup = lib.mkOption {
      type = lib.types.str;
      example = "Hyprland";
      description = ''
        Command to launch desktop environment.
      '';
    };
  };
}
