{
  self,
  config,
  ...
}:

let
  name = "hearth";
  system = "x86_64-linux";
  ip = "10.69.42.2";
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
    boot.blacklistedKernelModules = [
      "amdgpu"
      "radeon"
    ];
    dot.nix.gc = false;
    dot.hardware.temp = "/sys/class/hwmon/hwmon2/temp1_input";
    dot.hardware.monitor.main = "DP-1";
  };

  homeManagerModule = {
    services.easyeffects.preset = "krk";
  };
}
