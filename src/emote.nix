{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;

  paste =
    if hasWayland
    then "${pkgs.wl-clipboard}/bin/wl-paste"
    else "${pkgs.xclip}/bin/xclip -o -sel clipboard";
in
{
  branch.homeManagerModule.homeManagerModule = (lib.mkIf (hasMonitor && hasKeyboard)) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "e";
        command = "bash -c '${pkgs.smile}/bin/smile; ${paste}'";
      }
    ];

    dot.desktopEnvironment.windowrules = [{
      rule = "float";
      selector = "class";
      xselector = "wm_class";
      arg = "it.mijorus.smile";
      xarg = "smile";
    }];

    home.packages = [
      pkgs.smile
    ];
  };
}
