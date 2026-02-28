{ config, ... }:

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

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-network-manager = config.flake.lib.test.mkTest pkgs {
        name = "critical-network-manager";
        nodes.test = {
          imports = [ config.flake.nixosModules.critical-network-manager ];
          options.dot.hardware.network.enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
        };
        script = ''
          start_all()
          test.succeed("systemctl is-enabled nftables.service")
          test.succeed("systemctl is-enabled NetworkManager.service")
        '';
      };
    };
}
