{ lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && hasWayland) {
    services.swayosd.enable = true;
    services.swayosd.display = config.dot.hardware.monitor.main;
  };
}
