{
  pkgs,
  config,
  lib,
  ...
}:

# TODO: logout menu
# TODO: switch-layout, current-layout and logout should be through nix

let
  colors = config.lib.stylix.colors.withHashtag;

  package = pkgs.polybarFull;

  fontSizePt = config.stylix.fonts.sizes.desktop;
  fontSizePx = fontSizePt * config.dot.hardware.monitor.dpi / 72;

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
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
        transparent = "#44${config.lib.stylix.colors.base00}";
        background = colors.base00;
        background-alternate = colors.base01;
        background-inverted = colors.base08;
        text = colors.base09;
        text-alternate = colors.base10;
        primary = colors.base02;
        secondary = colors.base03;
        accent = colors.base06;
        danger = colors.red;
        monitor = config.dot.hardware.monitor.main;
        network-interface = config.dot.hardware.network.interface;
        cpu-hwmon = config.dot.hardware.temp;
        font =
          (builtins.toString config.stylix.fonts.sansSerif.name)
          + ":size="
          + (builtins.toString fontSizePt)
          + ";"
          + (builtins.toString ((32 - fontSizePx) / 2 - 2))
          + "px";
        font2 =
          (builtins.toString config.stylix.fonts.monospace.name)
          + ":size="
          + (builtins.toString fontSizePt)
          + ";"
          + (builtins.toString ((32 - fontSizePx) / 2 - 2))
          + "px";
        font3 =
          (builtins.toString config.stylix.fonts.emoji.name)
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
