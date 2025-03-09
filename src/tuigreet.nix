{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  integrate.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    desktopEnvironment.login =
      "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd '${config.dot.desktopEnvironment.startup}'";
  };
}
