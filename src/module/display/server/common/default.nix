{ lib, ... }:

{
  integrate.nixosModule.nixosModule.options.dot.desktopEnvironment = {
    login = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "tuigreet --cmd Hyprland";
      description = ''
        Login command.
      '';
    };
  };
}
