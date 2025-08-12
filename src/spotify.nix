{ pkgs, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.spotify-player
    ];
  };

  # NOTE: https://github.com/aome510/spotify-player/issues/796#issuecomment-3172148092
  branch.nixosModule.nixosModule = {
    networking.extraHosts = "0.0.0.0 apresolve.spotify.com";
  };
}
