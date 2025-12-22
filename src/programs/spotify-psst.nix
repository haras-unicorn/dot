{ pkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      pkgs.spotify-player
      pkgs.psst
    ];
  };
}
