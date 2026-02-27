# TODO: colors

{
  flake.homeModules.services-dunst =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasMonitor = config.dot.hardware.monitor.enable;
      hasWayland = config.dot.hardware.graphics.wayland;
    in
    lib.mkIf (hasMonitor && !hasWayland) {
      home.packages = [
        pkgs.libnotify
      ];

      services.dunst.enable = true;
      services.dunst.configFile = ./dunstrc;
    };
}
