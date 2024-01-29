{ nix-alien, system, ... }:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = [
    nix-alien.packages."${system}".nix-alien
  ];
}
