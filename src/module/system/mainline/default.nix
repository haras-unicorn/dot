{ pkgs, ... }:

{
  boot.kernelPackages = pkgs.linuxPackages;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  services.irqbalance.enable = true;
}
