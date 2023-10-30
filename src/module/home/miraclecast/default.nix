{ pkgs, ... }:

{
  home.packages = with pkgs; [
    miraclecast
  ];
}
