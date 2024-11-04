{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  home = lib.mkIf (hasMonitor && hasKeyboard) {
    home.packages = [
      pkgs.xfce.xfce4-terminal
    ];
  };
}
