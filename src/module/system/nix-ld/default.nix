{ pkgs
, system
, nix-alien
, nix-autobahn
, ...
}:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    nix-alien.packages."${system}".nix-alien
    nix-autobahn.packages."${system}".nix-autobahn
    steam-run
  ];
}
