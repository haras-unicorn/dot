{ pkgs, ... }:

{
  home = {
    home.packages = with pkgs; [
      kooha
    ];
  };
}
