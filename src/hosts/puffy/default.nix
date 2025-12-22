{
  self,
  config,
  ...
}:

let
  name = "puffy";
  system = "aarch64-linux";
  ip = "10.69.42.1";
in
{
  nixosConfigurationNixpkgs.system = system;
  nixosConfiguration = {
    imports = [
      self.nixosModules.host
      self.nixosModules."hosts-${name}"
    ];
    config.dot.host.name = name;
    config.dot.host.ip = ip;

    config.home-manager.users.${config.dot.host.user} = {
      imports = [
        self.homeManagerModules.host
        self.homeManagerModules."hosts-${name}"
      ];
    };
  };

  nixosModule = {
    dot.hardware.rpi."4".enable = true;
    dot.hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";

    dot.nebula.lighthouse = true;
    dot.ddns.enable = true;
    dot.consul.enable = true;
    dot.traefik.enable = true;
    dot.cockroachdb.enable = true;
    dot.cockroachdb.locality = "location=biden";
    dot.seaweedfs.enable = true;
    dot.seaweedfs.dataCenter = "biden";
    dot.seaweedfs.rack = "dot";
    dot.vault.enable = true;
    dot.vaultwarden.enable = true;
    dot.miniflux.enable = true;
  };

  homeManagerModule = { };
}
