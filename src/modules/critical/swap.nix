{
  machines.nixosModules.swap =
    { config, ... }:
    let
      hardware = config.dot.hardware;
    in
    {
      swapDevices = [
        {
          device = "/var/swap";
          size = hardware.memory / 1000 / 1000;
        }
      ];
    };
}
