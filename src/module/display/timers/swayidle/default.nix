{ pkgs, lib, config, ... }:

# FIXME: focused video not preventing locking

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    services.swayidle.enable = true;
    services.swayidle.timeouts = [
      {
        timeout = 60 * 5;
        command = "${pkgs.systemd}/bin/loginctl lock-session";
      }
      {
        timeout = 60 * 60;
        command = "${pkgs.systemd}/bin/systemctl suspend-then-hibernate";
      }
    ];
  };
}
