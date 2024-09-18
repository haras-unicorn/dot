{ pkgs, ... }:

{
  system = {
    boot.kernelPackages = pkgs.linuxPackages_6_9;
  };
}
