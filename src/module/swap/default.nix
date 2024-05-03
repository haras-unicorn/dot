{ lib, config, ... }:

{
  options.dot = {
    ram = lib.mkOption {
      type = lib.types.ints.u8;
      description = "In gigabytes; cat /proc/meminfo";
      example = 4;
    };
  };

  config = {
    system = {
      swapDevices = [
        {
          device = "/var/swap";
          size = config.dot.ram * 1024;
        }
      ];
    };
  };
}

