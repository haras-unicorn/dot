{ pkgs, ... }:

# TODO: bind

{
  home.packages = with pkgs; [ brightnessctl ];
}
