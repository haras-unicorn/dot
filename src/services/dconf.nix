{ pkgs, ... }:

{
  nixosModule = {
    programs.dconf.enable = true;
  };

  # NOTE: https://github.com/nix-community/home-manager/issues/3113
  homeManagerModule = {
    home.packages = [ pkgs.dconf ];
  };
}
