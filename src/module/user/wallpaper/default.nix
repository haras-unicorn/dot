{ self, pkgs, lib, config, ... }:

# NOTE: wallpaper inpaint/outpaint script for all resolutions

let
  name = "elden-ring";
  monitor = config.dot.hardware.monitor;
  graphics = config.dot.hardware.graphics;
  # default = "${self}/assets/wallpapers/${name}-${builtins.toString monitor.width}-${builtins.toString monitor.height}.png";
  default = "${self}/assets/wallpapers/${name}.png";
  wallpaper = config.dot.wallpaper;
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
      desktopEnvironment.sessionStartup = lib.mkIf monitor.enable [
        (lib.mkIf (!graphics.wayland) "feh --bg-fill '${wallpaper}'")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww-daemon")
        (lib.mkIf (graphics.wayland) "${pkgs.swww}/bin/swww img '${wallpaper}'")
      ];
    };
  };
}
