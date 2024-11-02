{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.via
    ];
  };
}
