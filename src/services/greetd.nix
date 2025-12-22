{ config, lib, ... }:

let
  cfg = config.dot.desktopEnvironment;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  nixosModule = lib.mkIf (hasMonitor && hasWayland) {
    services.greetd.enable = true;
    services.greetd.settings = {
      default_session = {
        command = cfg.login;
      };
    };
  };
}
