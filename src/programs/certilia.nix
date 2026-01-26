{ certilia-overlay, pkgs, ... }:

{
  homeManagerModule = {
    home.packages = [ certilia-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
