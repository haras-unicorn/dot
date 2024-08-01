{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = [
        pkgs.slack
      ];
    };
  };
}
