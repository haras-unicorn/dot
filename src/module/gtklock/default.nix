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

  home.shared = {
    home.packages = [
      pkgs.gtklock
    ];
  };
}
