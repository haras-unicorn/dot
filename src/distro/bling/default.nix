{ pkgs, ... }:

{
  home.shared = {
    home.packages = with pkgs; [
      fastfetch # NOTE: fetch
      krabby # NOTE: pokedex
      cmatrix # NOTE: matrix
      pokemonsay # NOTE: cowsay
      dotacat # NOTE: rainbow cat
    ];
  };
}
