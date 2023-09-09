{ pkgs, ... }:

{
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style.name = "Sweet-Dark";
  qt.style.package = pkgs.sweet;
}
