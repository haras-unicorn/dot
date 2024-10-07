{ pkgs, config, lib, ... }:

# TODO: logout menu
# TODO: switch-layout, current-layout and logout should be through nix

let
  bootstrap = config.dot.colors.bootstrap;
in
{
  home.shared = {
    home.activation = {
      polybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.polybar}/bin/polybar-msg cmd restart
      '';
    };

    services.polybar.enable = true;
    services.polybar.config = ./config.ini;
    services.polybar.settings = {
      nix = {
        transparent = bootstrap.background.normal.rgba 0.4;
        text = bootstrap.text.normal.hex;
        text-alternate = bootstrap.text.alternate.hex;
        primary = bootstrap.primary.normal.hex;
        secondary = bootstrap.secondary.normal.hex;
        accent = bootstrap.accent.normal.hex;
        monitor = config.dot.mainMonitor;
        network-interface = config.dot.networkInterface;
        cpu-hwmon = config.dot.cpuHwmon;
        font-family = config.dot.font.sans.name;
        font-size = config.dot.font.size.large;
      };
    };
  };
}
