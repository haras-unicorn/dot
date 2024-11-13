{ self, pkgs, lib, config, ... }:

# NOTE: wallpaper inpaint/outpaint script for all resolutions and select appropriate here

let
  name = "elden-ring";

  default = "${self}/assets/wallpapers/${name}.png";
  wallpaper = config.dot.wallpaper;

  hasWayland = config.dot.hardware.graphics.wayland;
  hasMonitor = config.dot.hardware.monitor.enable;

  setWallpaperXorg = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.feh ];
    text = ''
      feh --bg-fill "$1"
    '';
  };

  setWallpaperWayland = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.swww ];
    text = ''
      swww img "$1"
    '';
  };
in
{
  options = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = default;
      example = default;
    };
  };

  shared = {
    dot = {
      desktopEnvironment.sessionStartup = lib.mkMerge [
        (lib.mkIf (hasMonitor && !hasWayland) [
          "${pkgs.feh}/bin/feh --bg-fill '${wallpaper}'"
        ])
        (lib.mkIf (hasMonitor && hasWayland) [
          "${pkgs.swww}/bin/swww-daemon"
          "${pkgs.swww}/bin/swww img '${wallpaper}'"
        ])
      ];
    };
  };

  home = {
    home.packages = lib.mkMerge [
      (lib.mkIf (hasMonitor && hasWayland) [ setWallpaperWayland ])
      (lib.mkIf (hasMonitor && !hasWayland) [ setWallpaperXorg ])
    ];
  };
}
