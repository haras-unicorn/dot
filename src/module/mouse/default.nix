{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.polychromatic
    ];
  };
}
