{ config, ... }:

{
  config = {
    system = {
      swapDevices = [
        {
          device = "/var/swap";
          size = config.dot.hardware.memory / 1000 / 1000;
        }
      ];
    };
  };
}

