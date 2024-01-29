{ nix-alien, nix-autobahn, system, ... }:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = [
    nix-alien.packages."${system}".nix-alien
    nix-autobahn.packages."${system}".nix-autobahn
  ];
}
