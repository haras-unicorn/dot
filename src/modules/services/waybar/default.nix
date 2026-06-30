{
  machines.homeModules.waybar =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      desktop = config.dot.desktop;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      programs.waybar.enable = true;
      programs.waybar.systemd.enable = true;
      programs.waybar.systemd.targets = [ "graphical-session.target" ];
      programs.waybar.settings = [
        (pkgs.lib.attrsets.recursiveUpdate (builtins.fromJSON (builtins.readFile ./config.json)) {
          output = hardware.display;
          network = {
            interface = hardware.gateway;
          };
          temperature = {
            hwmon-path = hardware.temperature;
          };
          "custom/powermenu" = {
            on-click = desktop.logout;
          };
          "pulseaudio" = {
            "on-click" = desktop.volume;
          };
          "network" = {
            "on-click" = desktop.network;
          };
          "memory" = {
            "on-click" = desktop.monitor;
          };
          "cpu" = {
            "on-click" = desktop.monitor;
          };
        })
      ];

      programs.waybar.style = builtins.readFile ./style.css;
    };
}
