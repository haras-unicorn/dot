{ pkgs, ... }:

{
  system = {
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

  home = {
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
