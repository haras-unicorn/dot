{ pkgs, ... }:

# NOTE: https://github.com/NixOS/nixpkgs/issues/332350#issuecomment-2274071378

{
  system = {
    boot.kernelPackages = pkgs.linuxPackages;
  };
}
