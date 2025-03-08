{ pkgs, ... }:

{
  integrate.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.vim
    ];
  };
}
