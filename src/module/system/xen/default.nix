{ pkgs, ... }:

# FIXME: xen on efi https://github.com/NixOS/nixpkgs/issues/127404

{
  boot.kernelPackages = pkgs.linuxPackages_xen_dom0;
  services.ananicy.enable = true;
  services.earlyoom.enable = true;
  services.irqbalance.enable = true;
}
