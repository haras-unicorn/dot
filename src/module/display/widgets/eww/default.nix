{ pkgs, lib, config, ... }:

# TODO: use instead of waybar
# TODO: hook up config like with waybar
# TODO: menues
# TODO: colors

let
  package = pkgs.eww;
  bin = "${package}/bin/eww";

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
  hasMouse = config.dot.hardware.mouse.enable;
in
{
  shared = lib.mkIf (hasMonitor && hasKeyboard && hasMouse && hasWayland) {
    dot = {
      desktopEnvironment.sessionStartup = [
        "${bin} daemon"
      ];
    };
  };

  home = lib.mkIf (hasMonitor && hasKeyboard && hasMouse && hasWayland) {
    home.packages = [
      package
    ];

    programs.eww.enable = true;
    programs.eww.package = package;
    programs.eww.configDir = ./config;
  };
}
