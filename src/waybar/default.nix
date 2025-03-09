{ pkgs, config, lib, ... }:

# TODO: config paths for executables
# TODO: switch-layout, current-layout and logout should be through nix

let
  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    home.activation = {
      waybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.procps}/bin/pkill --signal "SIGUSR1" "waybar" || true
      '';
    };

    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.settings = [
      (pkgs.lib.attrsets.recursiveUpdate
        (builtins.fromJSON (builtins.readFile ./config.json))
        {
          output = config.dot.hardware.monitor.main;
          network = { interface = config.dot.hardware.network.interface; };
          temperature = {
            hwmon-path = config.dot.hardware.temp;
          };
        })
    ];

    programs.waybar.style = builtins.readFile ./style.css;
  };
}
