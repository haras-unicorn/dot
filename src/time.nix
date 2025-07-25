{ pkgs, ... }:

{
  branch.nixosModule.nixosModule = {
    services.timesyncd.enable = false;
    services.chrony = {
      enable = true;
      enableNTS = true;
      servers = [
        "time.cloudflare.com"
        "time.google.com"
        "0.nixos.pool.ntp.org"
        "1.nixos.pool.ntp.org"
        "2.nixos.pool.ntp.org"
        "3.nixos.pool.ntp.org"
      ];
      initstepslew = {
        enabled = true;
        threshold = 0.1;
      };
      extraConfig = ''
        makestep 0.1 3
      '';
    };

    systemd.targets.time-synced = {
      description = "System Time Synchronized";
      wantedBy = [ "multi-user.target" ];
    };

    systemd.services.time-sync-wait = {
      description = "Wait for time synchronization";
      after = [ "chronyd.service" ];
      requires = [ "chronyd.service" ];

      before = [ "time-synced.target" ];
      wantedBy = [ "time-synced.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${
            pkgs.writeShellApplication {
              name = "wait-for-time-sync";
              runtimeInputs = [ pkgs.systemd pkgs.gnugrep pkgs.coreutils ];
              text = ''
                until timedatectl | grep -q "System clock synchronized: yes"; do
                  systemctl restart chronyd
                  sleep 10
                done
              '';
            }
          }/bin/wait-for-time-sync";
        TimeoutStartSec = "5min";
      };
    };
  };
}
