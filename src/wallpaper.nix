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
  branch.homeManagerModule.homeManagerModule = {
    options.dot = {
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = "${self}/assets/wallpaper.mp4";
      };
    };

    config = {
      dot.desktopEnvironment.sessionStartup =
        lib.mkIf (hasMonitor && hasWayland) [
          ''${setWallpaperWayland}/bin/wallpaper ${config.dot.wallpaper}''
        ];

      stylix.targets.hyprpaper.enable = lib.mkForce false;
      home.packages = lib.mkMerge [
        (lib.mkIf (hasMonitor && hasWayland) [ setWallpaperWayland ])
        (lib.mkIf (hasMonitor && !hasWayland) [ setWallpaperXorg ])
      ];
    };
  };
}
