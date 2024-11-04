{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
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

  config = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    shared = {
      dot = {
        desktopEnvironment.login =
          "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd '${config.dot.desktopEnvironment.startup}'";
      };
    };
  };
}
