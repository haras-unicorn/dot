{ self, pkgs, lib, config, ... }:

let
  name = "elden-ring";
  monitor = config.dot.hardware.monitor;
  graphics = config.dot.hardware.graphics;
  default = "${self}/assets/wallpapers/${name}-${monitor.width}-${monitor.height}.png";
  wallpaper = config.dot.wallpaper;
in
{
  option = {
    wallpaper = lib.mkOption {
      type = lib.types.str;
      default = default;
      example = default;
    };
  };

  shared = {
    dot = {
      desktopEnvironment.sessionStartup = lib.mkIf monitor.enable [
        (lib.mkIf (!graphics.wayland) "feh --bg-fill '${wallpaper}'")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww-daemon")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww img '${wallpaper}'")
      ];
    };
  };
}
