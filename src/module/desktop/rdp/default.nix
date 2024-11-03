{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = [
        pkgs.remmina
      ];
    };
  };
}
