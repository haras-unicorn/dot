{
  self,
  config,
  ...
}:

let
  name = "workbug";
  system = "x86_64-linux";
  ip = "10.69.42.3";
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
    config.dot.host.pass = false;

    config.home-manager.users.${config.dot.host.user} = {
      imports = [
        self.homeManagerModules.host
        self.homeManagerModules."hosts-${name}"
      ];
    };
  };

  nixosModule = {
    dot.hardware.temp = "/sys/class/hwmon/hwmon3/temp1_input";
    dot.hardware.monitor.main = "eDP-1";

    dot.hardware.battery.enable = true;
  };

  homeManagerModule = {
    dot.mommy.enable = false;
    dot.wallpaper.static = true;
  };
}
