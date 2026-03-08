{ self, config, ... }:

let
  name = "hearth";
  system = "x86_64-linux";
  ip = "${config.dot.network.subnet.prefix}.2";
in
{
  flake.nixosConfigurations.${name} = self.lib.host.mkHost {
    inherit name system ip;
  };

  flake.nixosModules."hosts-${name}" = {
    boot.blacklistedKernelModules = [
      "amdgpu"
      "radeon"
    ];
    dot.nix.gc = false;
    dot.hardware.temp = "/sys/class/hwmon/hwmon2/temp1_input";
    dot.hardware.monitor.main = "DP-1";
    dot.host.pass = false;
    dot.seaweedfs.enableHomeMount = true;
    dot.cockroachdb.enableUserConnection = true;
  };

  flake.homeModules."hosts-${name}" = {
    services.easyeffects.preset = "krk";
    dot.wallpaper.static = true;
  };
}
