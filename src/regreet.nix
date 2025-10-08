{
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    # NOTE: force because still keeping tuigreet config for now
    dot.desktopEnvironment.login = lib.mkForce "${config.programs.regreet.package}/bin/regreet";

    programs.regreet.enable = true;
  };
}
