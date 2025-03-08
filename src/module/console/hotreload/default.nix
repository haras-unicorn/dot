{ pkgs, ... }:

# TODO: script

{
  integrate.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.watchexec
      pkgs.systemfd
    ];
  };
}
