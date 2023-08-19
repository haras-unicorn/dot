{ nixos-hardware, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
  ];
}
