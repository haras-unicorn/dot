{ pkgs, config, lib, ... }:

# TODO: logout menu
# TODO: switch-layout, current-layout and logout should be through nix

let
  bootstrap = config.dot.colors.bootstrap;

  package = pkgs.polybarFull;
in
{
  home.shared = {
    home.activation = {
      polybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${package}/bin/polybar-msg cmd restart
      '';
    };

    services.polybar.enable = true;
    services.polybar.config = ./config.ini;
    services.polybar.package = package;
    services.polybar.script = "${package}/bin/polybar top &>/dev/null & disown %-";
    services.polybar.settings = {
      nix = {
        background = bootstrap.background.normal.hex;
        text = bootstrap.text.normal.hex;
        text-alternate = bootstrap.text.alternate.hex;
        primary = bootstrap.primary.normal.hex;
        secondary = bootstrap.secondary.normal.hex;
        accent = bootstrap.accent.normal.hex;
        monitor = config.dot.mainMonitor;
        network-interface = config.dot.networkInterface;
        cpu-hwmon = config.dot.cpuHwmon;
        font = (builtins.toString config.dot.font.sans.name)
          + ":size="
          + (builtins.toString config.dot.font.size.large);
      };
    };
  };
}
