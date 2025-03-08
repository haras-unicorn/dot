{ pkgs, lib, config, ... }:

let
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasMouse = config.dot.hardware.mouse.enable;
in
{
  config = lib.mkIf (hasMonitor && hasKeyboard && hasMouse && (!hasWayland)) {
    desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "Print";
        command = "${pkgs.flameshot}/bin/flameshot gui -p '${config.xdg.userDirs.pictures}/screenshots'";
      }
    ];
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    services.flameshot.enable = true;
  };
}
