{ lib, config, ... }:

let
  cfg = config.dot.hardware;
in
with lib;
{
  options.dot.hardware = {
    ram = mkOption {
      type = with types; ints.u8;
      description = "In gigabytes; cat /proc/meminfo";
      example = 4;
    };
  };

  config = {
    system = {
      swapDevices = [
        {
          device = "/var/swap";
          size = cfg.ram * 1024;
        }
      ];
    };
  };
}

