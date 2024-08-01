{ pkgs, ... }:

# TODO: xen on efi https://github.com/NixOS/nixpkgs/pull/324693

{
  system = {
    boot.kernelPackages = pkgs.linuxPackages_xen_dom0;
    services.ananicy.enable = true;
    services.earlyoom.enable = true;
    services.irqbalance.enable = true;
  };
}
