{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;

  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = (lib.mkIf (hasMonitor && hasKeyboard)) {
    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "e";
        command = "${pkgs.smile}/bin/smile";
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
