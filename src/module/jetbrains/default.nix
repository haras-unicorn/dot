{ pkgs, ... }:

{
  home.shared = {
    home.packages = with pkgs.jetbrains; [
      rider
    ];
  };
}
