{ pkgs, ... }:

{
  home.shared = {
    home.packages = with pkgs; [
      peek
    ];
  };
}
