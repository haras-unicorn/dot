{ self, config, ... }:

let
  name = "koncar9000";
  system = "x86_64-linux";
  ip = "${config.dot.network.subnet.prefix}.7";
in
{
  flake.nixosConfigurations.${name} = self.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    # FIXME: set to actual values
    dot.hardware.temp = "/sys/class/hwmon/hwmon3/temp1_input";
    dot.hardware.monitor.main = "eDP-1";
    dot.host.pass = false;
  };

  flake.homeModules."hosts-${name}" = {
    dot.wallpaper.static = true;
  };
}
