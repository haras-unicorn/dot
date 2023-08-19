{ nixos-hardware, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
  ];

  nixpkgs.buildPlatform = "x86_64-linux";
}
