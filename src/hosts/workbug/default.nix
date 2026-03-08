{ self, config, ... }:

let
  name = "workbug";
  system = "x86_64-linux";
  ip = "${config.dot.network.subnet.prefix}.3";
in
{
  flake.nixosConfigurations.${name} = self.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    dot.hardware.temp = "/sys/class/hwmon/hwmon3/temp1_input";
    dot.hardware.monitor.main = "eDP-1";
    dot.hardware.battery.enable = true;
    dot.host.pass = false;
  };

  flake.homeModules."hosts-${name}" = {
    dot.mommy.enable = false;
    dot.wallpaper.static = true;
  };
}
