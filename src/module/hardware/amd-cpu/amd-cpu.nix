{ ... }:

{
  boot.kernelModules = [
    "kvm-amd"
  ];

  hardware.cpu.amd.updateMicrocode = true;

  programs.corectrl.enable = true;
}
