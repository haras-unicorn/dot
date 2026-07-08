{
  self.lib.deprecated.homeModules.waybar =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      desktop = config.dot.desktop;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      programs.waybar.enable = true;
      programs.waybar.systemd.enable = true;
      programs.waybar.settings = [
        (pkgs.lib.attrsets.recursiveUpdate (builtins.fromJSON (builtins.readFile ./config.json)) {
          output = hardware.display;
          network = {
            interface = hardware.interface;
          };
          temperature = {
            hwmon-path = hardware.temperature;
          };
          "custom/powermenu" = {
            on-click = desktop.logout;
          };
          "pulseaudio" = {
            "on-click" = desktop.volume;
          };
          "network" = {
            "on-click" = desktop.network;
          };
          "memory" = {
            "on-click" = desktop.monitor;
          };
          "cpu" = {
            "on-click" = desktop.monitor;
          };
          "systemd-failed-units" = {
            "on-click" = desktop.monitor;
          };
        })
      ];

      programs.waybar.style = builtins.readFile ./style.css;

      # NOTE: for some reason it doesn't have this set up
      systemd.user.services.waybar = {
        Unit.Before = [ "tray.target" ];
      };

      # NOTE: waybar tells systemd it started too early
      # breaking qt apps that want systray
      systemd.user.services.waybar-tray-ready = {
        Install.WantedBy = [
          "tray.target"
          "graphical-session.target"
        ];
        Unit = {
          Description = "Wait for waybar tray to become ready";
          PartOf = [
            "graphical-session.target"
            "tray.target"
          ];
          Requires = [ "waybar.service" ];
          After = [
            "waybar.service"
            "graphical-session.target"
          ];
          Before = [ "tray.target" ];
        };
        Service = {
          Type = "oneshot";
          RemainAfterExit = true;
          TimeoutStartSec = 30;
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "wait-for-waybar-tray";
              text = ''
                while ! ${pkgs.systemd}/bin/journalctl --user -u waybar.service --no-pager -n 100 -q \
                  | grep -q "Bar configured"; do
                  sleep 0.1
                done
                sleep 1
              '';
            }
          );
        };
      };
    };
}
