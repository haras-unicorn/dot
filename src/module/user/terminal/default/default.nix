{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.xfce.xfce4-terminal
    ];
  };
}
