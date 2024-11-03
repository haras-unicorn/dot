{ self, lib, config, ... }:

let
  name = "elden-ring";
  cfg = config.dot.hardware.monitor;
in
{
  shared = lib.mkIf cfg.enable {
    dot = {
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = "${self}/assets/wallpaper/${name}-${cfg.width}-${cfg.height}.png";
      };
    };
  };
}
