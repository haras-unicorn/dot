{ self, ... }:

# NOTE: do not enable NTS because time can be so far off sometimes
# that it registers certs as invalid
# TODO: enable NTS after first sync

{
  flake.nixosModules.critical-chronyd =
    { lib, pkgs, ... }:
    {
      services.timesyncd.enable = false;

      networking.timeServers = [
        # Google
        "216.239.35.0"
        "216.239.35.4"
        "216.239.35.8"
        "216.239.35.12"

        # Cloudflare
        "162.159.200.1"
        "162.159.200.123"
      ];

      services.chrony = {
        enable = true;
        initstepslew = {
          enabled = true;
          threshold = 1;
        };
      };

      systemd.services.chronyd.after = [ "network-online.target" ];
      systemd.services.chronyd.requires = [ "network-online.target" ];
      systemd.services.chronyd.serviceConfig = {
        Restart = lib.mkForce "always";
      };

      systemd.services.chronyd-sync-wait = {
        description = "Wait for synchronization from chrony";
        after = [ "chronyd.service" ];
        bindsTo = [ "chronyd.service" ];
        wantedBy = [ "chronyd.service" ];
        path = [ pkgs.chrony ];
        script = ''
          while true; do
            if timedatectl | grep -q "System clock synchronized: yes"; then
              exit 0
            fi
            chronyc makestep
            sleep 10
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StandardOutput = "journal";
          TimeoutStartSec = "infinity";
          Restart = "on-failure";
        };
      };

      systemd.targets.dot-time-synchronized = {
        bindsTo = [
          "chronyd.service"
          "chronyd-sync-wait.service"
        ];
        wantedBy = [ "chronyd.service" ];
        after = [
          "chronyd.service"
          "chronyd-sync-wait.service"
        ];
      };

      programs.rust-motd.settings = {
        service_status = {
          Chrony = "chronyd";
        };
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-chronyd = self.lib.test.mkTest pkgs {
        name = "critical-chronyd";
        dot.test.ntp.enable = true;
        nodes.machine = {
          imports = [ self.nixosModules.critical-chronyd ];

          systemd.services.time-dependant = {
            description = "Service dependant on time synchronization";
            wantedBy = [ "dot-time-synchronized.target" ];
            requires = [ "dot-time-synchronized.target" ];
            after = [ "dot-time-synchronized.target" ];
            script = ''
              while true; do
                sleep 10
                timedatectl
              done
            '';
          };
        };
        dot.test.commands.suffix =
          { nodes, ... }:
          ''
            machine.succeed("which chronyd")
            machine.succeed("which chronyc")
            machine.succeed("chronyc sources | grep -q '${nodes.ntp.dot.host.ip}'")
            machine.wait_for_unit("dot-time-synchronized.target", timeout=60)

            # NOTE: expected stop
            machine.succeed("systemctl stop chronyd")
            machine.fail("systemctl is-active dot-time-synchronized.target")
            machine.fail("systemctl is-active time-dependant.service")
            machine.succeed("systemctl start chronyd")
            machine.wait_for_unit("chronyd-sync-wait.service", timeout=60)
            machine.wait_for_unit("dot-time-synchronized.target", timeout=60)
            machine.wait_for_unit("time-dependant.service", timeout=60)

            # NOTE: unexpected stop
            machine.succeed("pkill -sigterm chronyd")
            machine.fail("systemctl is-active dot-time-synchronized.target")
            machine.fail("systemctl is-active time-dependant.service")
            machine.wait_for_unit("chronyd-sync-wait.service", timeout=60)
            machine.wait_for_unit("dot-time-synchronized.target", timeout=60)
            machine.wait_for_unit("time-dependant.service", timeout=60)

            # NOTE: failure
            machine.succeed("pkill -sigkill chronyd")
            machine.fail("systemctl is-active dot-time-synchronized.target")
            machine.fail("systemctl is-active time-dependant.service")
            machine.succeed("systemctl start chronyd")
            machine.wait_for_unit("chronyd-sync-wait.service", timeout=60)
            machine.wait_for_unit("dot-time-synchronized.target", timeout=60)
            machine.wait_for_unit("time-dependant.service", timeout=60)
          '';
      };
    };
}
