{
  self,
  config,
  ...
}:

let
  name = "officer";
  system = "x86_64-linux";
  ip = "10.69.42.4";
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
    dot.hardware.temp = "/sys/class/hwmon/hwmon0/temp1_input";
    dot.hardware.monitor.main = "DVI-D-0";
    dot.host.pass = false;
  };

  homeManagerModule = {
    dot.mommy.enable = false;
  };
}
