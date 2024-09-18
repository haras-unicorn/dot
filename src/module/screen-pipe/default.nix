{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = with pkgs; [
        screen-pipe
      ];
    };
  };
}