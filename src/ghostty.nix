{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.ghostty
    ];
    xdg.configFile."ghostty/config" = lib.mkIf (hasKeyboard && hasMonitor) ''
      cursor-style block
      cursor-style-blink false
    '';
  };
}
