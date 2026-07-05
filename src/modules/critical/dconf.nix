# NOTE: https://github.com/nix-community/home-manager/issues/3113

{
  machines.nixosModules.dconf =
    { pkgs, ... }:
    {
      programs.dconf.enable = true;
    };

  machines.homeModules.dconf =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.dconf ];
    };
}
