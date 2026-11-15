{
  self.nixosModules.swap.value =
    { config, ... }:
    let
      hardware = config.dot.hardware;
      swapDirectory = "/var/lib/swap";
    in
    {
      swapDevices = [
        {
          device = "${swapDirectory}/swapfile";
          size = hardware.memory / 1000 / 1000;
        }
      ];

      # NOTE: kept as a database folder only because that makes it not copy on
      # write, which a swap file on btrfs has to be
      stolon.keep.databases = [ swapDirectory ];
    };
}
