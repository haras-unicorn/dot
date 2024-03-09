{ pkgs, ... }:

{
  home.packages = with pkgs; [
    peek
  ];
}
