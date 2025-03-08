{ pkgs, lib, config, ... }:

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
  hasKeyboard = config.dot.hardware.keyboard.enable;
in
{
  integrate.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    security.pam.services.gtklock = { };
    services.systemd-lock-handler.enable = true;

    systemd.user.services.gtklock = {
      description = "GTK Lock Service";
      wantedBy = [ "lock.target" "sleep.target" ];
      before = [ "sleep.target" ];
      script = "${pkgs.gtklock}/bin/gtklock";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  integrate.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasKeyboard && hasWayland) {
    home.packages = [
      pkgs.gtklock
    ];

    services.swayidle.events = [
      {
        event = "lock";
        command = "${pkgs.gtklock}/bin/gtklock -d";
      }
      {
        event = "before-sleep";
        command = "${pkgs.gtklock}/bin/gtklock -d";
      }
    ];
  };
}
