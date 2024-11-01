{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs; [
      peek
    ];
  };
}
