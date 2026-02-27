{ pkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      pkgs.opencode
    ];
  };
}
