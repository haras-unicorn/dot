{ pkgs, ... }:

{
  home.shared = {
    home.packages = with pkgs; [
      fastfetch # NOTE: fetch
      krabby # NOTE: pokedex
      cmatrix # NOTE: matrix
    ];
  };
}
