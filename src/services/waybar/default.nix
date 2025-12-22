{
  pkgs,
  config,
  lib,
  ...
}:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.systemd.target = "graphical-session.target";
    programs.waybar.settings = [
      (pkgs.lib.attrsets.recursiveUpdate (builtins.fromJSON (builtins.readFile ./config.json)) {
        output = config.dot.hardware.monitor.main;
        network = {
          interface = config.dot.hardware.network.interface;
        };
        temperature = {
          hwmon-path = config.dot.hardware.temp;
        };
        "custom/powermenu" = {
          on-click = config.dot.desktopEnvironment.logout;
        };
        "pulseaudio" = {
          "on-click" = config.dot.desktopEnvironment.volume;
        };
        "network" = {
          "on-click" = config.dot.desktopEnvironment.network;
        };
        "memory" = {
          "on-click" = config.dot.desktopEnvironment.monitor;
        };
        "cpu" = {
          "on-click" = config.dot.desktopEnvironment.monitor;
        };
      })
    ];

    programs.waybar.style = builtins.readFile ./style.css;
  };
}
