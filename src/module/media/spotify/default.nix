{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.psst
    ];
  };
}
