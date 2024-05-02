{ pkgs, ... }:

{
  system = {
    boot.kernelPackages = pkgs.linuxPackages_zen;

    services.ananicy.enable = true;
    services.earlyoom.enable = true;
    services.irqbalance.enable = true;
  };
}
