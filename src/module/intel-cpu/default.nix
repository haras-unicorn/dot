{ lib, ... }:

{
  options = {
    dot = {
      cpuHwmon = lib.mkOption {
        type = lib.types.str;
        description = "ls /sys/class/hwmon";
        example = "/sys/class/hwmon/hwmon1/temp1_input";
      };
    };
  };

  config = {
    system = {
      boot.kernelModules = [
        "kvm-intel"
        "cpuid"
      ];

      hardware.cpu.intel.updateMicrocode = true;

      programs.corectrl.enable = true;
    };
  };
}
