{
  pkgs,
  lib,
  config,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  type = if hasWayland then "${pkgs.wtype}/bin/wtype" else "${pkgs.xdotool}/bin/xdotool type";
in
{
  branch.homeManagerModule.homeManagerModule = (lib.mkIf (hasMonitor && hasKeyboard)) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "e";
        command = "bash -c '${pkgs.smile}/bin/smile; ${type} $(paste)'";
      }
    ];

    dot.desktopEnvironment.windowrules = [
      {
        rule = "float";
        selector = "class";
        arg = "it.mijorus.smile";
      }
    ];

    home.packages = [
      pkgs.smile
    ];
  };
}
