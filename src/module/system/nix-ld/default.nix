{ nix-alien, ... }:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = [
    nix-alien.packages.default
  ];
}
