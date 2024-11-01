{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs.jetbrains; [
      rider
    ];
  };
}
