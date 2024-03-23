{ pkgs, ... }:

{
  home.packages = with pkgs; [
    spotify
    psst
  ];
}
