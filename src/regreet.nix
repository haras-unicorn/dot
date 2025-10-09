{
  lib,
  config,
  pkgs,
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
    dot.desktopEnvironment.login = lib.mkForce (
      (lib.getExe' pkgs.dbus "dbus-run-session")
      + " "
      + (lib.getExe pkgs.cage)
      + " "
      + (lib.escapeShellArgs config.programs.regreet.cageArgs)
      + " -- "
      + (lib.getExe config.programs.regreet.package)
    );

    programs.regreet.enable = true;
  };
}
