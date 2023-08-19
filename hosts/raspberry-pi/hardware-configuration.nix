{ nixpkgs, nixos-hardware, ... }:

{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-4
    "<nixpkgs>/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
}
