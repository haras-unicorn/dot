{ pkgs, ... }:

{
  branch.nixosModule.nixosModule = {
    services.timesyncd.enable = false;
    # NOTE: do not enable NTS because time can be so far off sometimes
    # that it registers certs as invalid
    services.chrony = {
      enable = true;
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
        threshold = 1;
      };
    };

    programs.rust-motd.settings = {
      service_status = {
        Chrony = "chronyd";
      };
    };

    systemd.services.chronyd.after = [ "network-online.target" ];
    systemd.services.chronyd.requires = [ "network-online.target" ];

    systemd.targets.time-synced = {
      description = "System Time Synchronized";
      wantedBy = [ "multi-user.target" ];
      requires = [ "chrony-time-sync-wait.service" ];
      after = [ "chrony-time-sync-wait.service" ];
    };

    systemd.services.chrony-time-sync-wait = {
      description = "Wait for time synchronization from chrony";
      after = [ "chronyd.service" ];
      requires = [ "chronyd.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        TimeoutStartSec = "infinity";
        ExecStart = "${
          pkgs.writeShellApplication {
            name = "wait-for-time-sync";
            runtimeInputs = [
              pkgs.chrony
              pkgs.coreutils
            ];
            text = ''
              if timedatectl | grep -q "System clock synchronized: yes"; then
                exit 0
              fi
              while true; do
                sleep 10
                if timedatectl | grep -q "System clock synchronized: yes"; then
                  exit 0
                fi
                chronyc makestep
              done
            '';
          }
        }/bin/wait-for-time-sync";
      };
    };
  };
}
