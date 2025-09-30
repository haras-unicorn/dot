{ pkgs, ... }:

{
  branch.nixosModule.nixosModule = {
    programs.dconf.enable = true;
  };

  # NOTE: https://github.com/nix-community/home-manager/issues/3113
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [ pkgs.dconf ];
  };
}
