{ self, config, ... }:

let
  name = "puffy";
  system = "aarch64-linux";
  ip = "${config.dot.network.subnet.prefix}.1";
in
{
  flake.nixosConfigurations.${name} = self.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    dot.hardware.rpi."4".enable = true;
    dot.hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";

    dot.locality.region = "origin";
    dot.locality.dataCenter = "biden";
    dot.locality.rack = "shelf";

    dot.critical.enable = true;
  };

  flake.homeModules."hosts-${name}" = { };
}
