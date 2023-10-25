{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lmms
    ardour
    zrythm
  ];
}
