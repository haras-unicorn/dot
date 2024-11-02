{ pkgs, ... }:

{
  system = {
    boot.kernelPackages = pkgs.linuxPackages;
  };
}
