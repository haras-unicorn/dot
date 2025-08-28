{ pkgs, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.spotify-player
      pkgs.psst
    ];
  };
}
