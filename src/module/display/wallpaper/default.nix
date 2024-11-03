{ self, pkgs, lib, config, ... }:

let
  name = "elden-ring";
  monitor = config.dot.hardware.monitor;
  graphics = config.dot.hardware.graphics;
  wallpaper = "${self}/assets/wallpapers/${name}-${monitor.width}-${monitor.height}.png";
in
{
  option = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
    };
  };

  shared = lib.mkIf monitor.enable {
    dot = {
      inherit wallpaper;

      desktopEnvironment.sessionStartup = [
        (lib.mkIf (!graphics.wayland) "feh --bg-fill '${wallpaper}'")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww-daemon")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww img '${wallpaper}'")
      ];
    };
  };
}
