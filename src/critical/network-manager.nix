{ ... }:

{
  flake.nixosModules.critical-network-manager =
    {
      pkgs,
      lib,
      config,
      ...
    }:

    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    {
      config = lib.mkIf hasNetwork {
        networking.nftables.enable = true;
        networking.firewall.enable = true;

        networking.networkmanager.enable = true;
        systemd.network.wait-online.enable = false;

        programs.rust-motd.settings = {
          service_status = {
            Network = "systemd-networkd";
          };
        };
      };
    };
}
