{ pkgs, ... }:

# NOTE: do not enable NTS because time can be so far off sometimes
# that it registers certs as invalid
# TODO: enable NTS after first sync

{
  nixosModule = {
    services.timesyncd.enable = false;
    services.chrony = {
      enable = true;
      servers = [
        # Google
        "216.239.35.0"
        "216.239.35.4"
        "216.239.35.8"
        "216.239.35.12"

        # Cloudflare
        "162.159.200.1"
        "162.159.200.123"
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

    systemd.targets.chronyd-synced = {
      description = "Chrony Daemon Synchronized";
      wantedBy = [ "multi-user.target" ];
      requires = [ "chronyd-sync-wait.service" ];
      after = [ "chronyd-sync-wait.service" ];
    };

    systemd.services.chronyd-sync-wait = {
      description = "Wait for synchronization from chrony";
      after = [ "chronyd.service" ];
      requires = [ "chronyd.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StandardOutput = "journal";
        TimeoutStartSec = "infinity";
        ExecStart = "${
          pkgs.writeShellApplication {
            name = "chronyd-sync-wait";
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
        }/bin/chronyd-sync-wait";
      };
    };
  };
}
