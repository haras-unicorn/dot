{ ... }:

{
  system = {
    boot.kernelModules = [
      "kvm-intel"
      "cpuid"
    ];

    hardware.cpu.intel.updateMicrocode = true;

    programs.corectrl.enable = true;
  };
}
