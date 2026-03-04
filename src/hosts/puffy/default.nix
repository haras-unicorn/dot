{ config, ... }:

let
  name = "puffy";
  system = "aarch64-linux";
  ip = "10.69.42.1";
in
{
  flake.nixosConfigurations.${name} = config.flake.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    dot.hardware.rpi."4".enable = true;
    dot.hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";
    dot.nebula.lighthouse = true;
    dot.ddns.enable = true;
    dot.consul.enable = true;
    dot.traefik.enable = true;
    dot.cockroachdb.enable = true;
    dot.cockroachdb.locality = "region=origin,datacenter=biden";
    dot.seaweedfs.enable = true;
    dot.seaweedfs.dataCenter = "biden";
    dot.seaweedfs.rack = "dot";
    dot.vault.enable = true;
    dot.vaultwarden.enable = true;
    dot.miniflux.enable = true;
  };

  flake.homeModules."hosts-${name}" = { };
}
