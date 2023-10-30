{ ... }:

{
  boot.kernelModules = [
    "kvm-amd"
    "cpuid"
  ];

  hardware.cpu.amd.updateMicrocode = true;

  programs.corectrl.enable = true;
}
