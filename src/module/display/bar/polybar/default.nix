{ pkgs, config, lib, ... }:

# TODO: logout menu
# TODO: switch-layout, current-layout and logout should be through nix

let
  bootstrap = config.dot.colors.bootstrap;

  package = pkgs.polybarFull;

  fontSizePt = config.dot.font.size.large;
  fontSizePx = fontSizePt * config.dot.hardware.monitor.dpi / 72;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  home = lib.mkIf (hasMonitor && !hasWayland) {
    home.activation = {
      polybarReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${package}/bin/polybar-msg cmd restart || true
      '';
    };

    services.polybar.enable = true;
    services.polybar.config = ./config.ini;
    services.polybar.package = package;
    services.polybar.script = "${package}/bin/polybar top &>/dev/null & disown %-";
    services.polybar.settings = rec {
      nix = {
        width = "${builtins.toString (config.dot.hardware.monitor.width - 16)}px";
        transparent = bootstrap.background.normal.ahex "44";
        background = bootstrap.background.normal.hex;
        background-alternate = bootstrap.background.alternate.hex;
        background-inverted = bootstrap.background.inverted.hex;
        text = bootstrap.text.normal.hex;
        text-alternate = bootstrap.text.alternate.hex;
        primary = bootstrap.primary.normal.hex;
        secondary = bootstrap.secondary.normal.hex;
        accent = bootstrap.accent.normal.hex;
        danger = bootstrap.danger.normal.hex;
        monitor = config.dot.hardware.monitor.main;
        network-interface = config.dot.hardware.network.interface;
        cpu-hwmon = config.dot.hardware.temp;
        font = (builtins.toString config.dot.font.sans.name)
          + ":size="
          + (builtins.toString fontSizePt)
          + ";"
          + (builtins.toString ((32 - fontSizePx) / 2 - 2))
          + "px";
        font2 = (builtins.toString config.dot.font.nerd.name)
          + ":size="
          + (builtins.toString fontSizePt)
          + ";"
          + (builtins.toString ((32 - fontSizePx) / 2 - 2))
          + "px";
        font3 = (builtins.toString config.dot.font.emoji.name)
          + ":size="
          + (builtins.toString fontSizePt)
          + ";"
          + (builtins.toString ((32 - fontSizePx) / 2 - 2))
          + "px";
      };
      "module/battery" = {
        label-charging = "%{F${nix.accent}} %percentage%%{F-}";
        label-discharging = "%{F${nix.text-alternate}} %percentage%%{F-}";
        label-full = "%{F${nix.text-alternate}} %percentage%%{F-}";
      };
      "module/pulseaudio" = {
        label-volume = "%{F${nix.text-alternate}}%percentage%%{F-}";
      };
      "module/temperature" = {
        label = "%{F${nix.text-alternate}}%temperature-c%%{F-}";
        label-warn = "%{F${nix.accent}}%temperature-c%%{F-}";
      };
      "module/memory" = {
        label = "%{F${nix.text-alternate}} %used%%{F-}";
      };
      "module/cpu" = {
        label = "%{F${nix.text-alternate}} %percentage%%{F-}";
      };
    };
  };
}
