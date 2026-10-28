# NOTE: https://github.com/nix-community/home-manager/issues/3113

{
  self.nixosModules.dconf.value =
    { pkgs, ... }:
    {
      programs.dconf.enable = true;
    };

  self.homeModules.dconf.value =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.dconf ];
    };
}
