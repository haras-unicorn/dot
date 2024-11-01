{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs; [
      miraclecast
    ];
  };
}
