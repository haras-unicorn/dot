{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs; [
      rnr
      fastmod
    ];
  };
}
