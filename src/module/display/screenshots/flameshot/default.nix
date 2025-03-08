{ pkgs, lib, config, ... }:

let
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasMouse = config.dot.hardware.mouse.enable;
in
{
  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    desktopEnvironment.keybinds = lib.mkIf (hasKeyboard && hasMouse) [
      {
        mods = [ "super" ];
        key = "Print";
        command = "${pkgs.flameshot}/bin/flameshot gui -p '${config.xdg.userDirs.pictures}/screenshots'";
      }
    ];

    services.flameshot.enable = true;
  };
}
