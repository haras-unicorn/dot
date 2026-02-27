# NOTE: https://github.com/nix-community/home-manager/issues/3113

{
  flake.nixosModules.services-dconf =
    { pkgs, ... }:
    {
      programs.dconf.enable = true;
    };

  flake.homeModules.services-dconf =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.dconf ];
    };
}
