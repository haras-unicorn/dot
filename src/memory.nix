{ config, lib, ... }:

let
  isRpi4 = config.dot.hardware.rpi."4".enable;
in
{
  branch.nixosModule.nixosModule = {
    services.preload.enable = (config.dot.hardware.memory / 1000 / 1000 / 1000) > 16;

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
    };
  };
}
