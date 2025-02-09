{ self, pkgs, lib, config, ... }:

let
  hasWayland = config.dot.hardware.graphics.wayland;
  hasMonitor = config.dot.hardware.monitor.enable;

  setWallpaperXorg = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.feh ];
    text = ''
      feh --bg-fill "$@"
    '';
  };

  setWallpaperWayland = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = [ pkgs.mpvpaper ];
    text = ''
      mpvpaper \
        -o "video-unscaled=yes no-audio --loop-playlist" \
        '*' "$@"
    '';
  };
in
{
  options = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = "${self}/assets/kuromi.mp4";
    };
  };

  config = {
    desktopEnvironment.sessionStartup =
      lib.mkIf (hasMonitor && hasWayland) [
        ''${setWallpaperWayland}/bin/wallpaper ${config.dot.wallpaper}''
      ];
  };

  home = {
    stylix.targets.hyprpaper.enable = lib.mkForce false;
    home.packages = lib.mkMerge [
      (lib.mkIf (hasMonitor && hasWayland) [ setWallpaperWayland ])
      (lib.mkIf (hasMonitor && !hasWayland) [ setWallpaperXorg ])
    ];
  };
}
