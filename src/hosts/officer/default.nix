{ self, config, ... }:

let
  name = "officer";
  system = "x86_64-linux";
  ip = "${config.dot.network.subnet.prefix}.4";
in
{
  flake.nixosConfigurations.${name} = self.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    dot.hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";
    dot.hardware.monitor.main = "DVI-D-0";
    dot.host.pass = false;
  };

  flake.homeModules."hosts-${name}" = {
    dot.mommy.enable = false;
  };
}
