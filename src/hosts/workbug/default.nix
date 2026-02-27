{ config, ... }:

let
  name = "workbug";
  system = "x86_64-linux";
  ip = "10.69.42.3";
in
{
  flake.nixosConfigurations.${name} = config.flake.lib.host.mkHost {
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
