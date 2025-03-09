{ pkgs, lib, config, ... }:

# TODO: colors

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
    home.packages = [
      pkgs.libnotify
    ];

    services.dunst.enable = true;
    services.dunst.configFile = ./dunstrc;
  };
}
