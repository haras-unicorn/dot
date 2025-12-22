{
  config,
  lib,
  pkgs,
  ...
}:

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  nixosModule = {
    services.ananicy.enable = !isRpi4;
    services.ananicy.package = pkgs.ananicy-cpp;

    services.earlyoom.enable = true;

    zramSwap.enable = isRpi4;

    swapDevices = (
      lib.mkIf (!isRpi4) [
        {
          device = "/var/swap";
          size = config.dot.hardware.memory / 1000 / 1000;
        }
      ]
    );

    programs.rust-motd.settings = {
      memory = {
        swap_pos = "beside";
      };
      load_avg = {
        format = "Load (1, 5, 15 min.): {one:.02}, {five:.02}, {fifteen:.02}";
      };
    };
  };
}
