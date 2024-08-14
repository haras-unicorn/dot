{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = [
        pkgs.local-ai
      ];
    };
  };
}
