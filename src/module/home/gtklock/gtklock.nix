{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gtklock
  ];
}
