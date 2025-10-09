{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  theme = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    dot.desktopEnvironment.login =
      "${pkgs.greetd.tuigreet}/bin/tuigreet"
      + " --sessions '${config.dot.desktopEnvironment.sessions}'"
      + " --user-menu"
      + " --theme '${theme}'"
      + " --asterisks"
      + " --remember"
      + " --remember-user-session";
  };
}
