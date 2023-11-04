{ pkgs, ... }:

{
  home.packages = with pkgs; [ alarm-clock-applet ];
} 
