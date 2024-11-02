{ pkgs, ... }:

# TODO: script

{
  home = {
    home.packages = [
      pkgs.watchexec
      pkgs.systemfd
    ];
  };
}
