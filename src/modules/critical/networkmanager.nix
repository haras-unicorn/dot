{
  machines.nixosModules.networkmanager =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      systemd.network.enable = false;
      systemd.network.wait-online.enable = false;

      networking.nftables.enable = true;
      networking.firewall.enable = true;

      networking.networkmanager.enable = true;
    };
}
