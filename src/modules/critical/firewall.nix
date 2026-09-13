{
  self.nixosModules.firewall.value =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      networking.nftables.enable = true;
      networking.firewall.enable = true;
    };
}
