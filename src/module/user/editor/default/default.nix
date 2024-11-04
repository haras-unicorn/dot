{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.vim
    ];
  };
}
