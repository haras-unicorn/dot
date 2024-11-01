{ pkgs, ... }:

{
  home = {
    home.packages = [
      pkgs.gpt4all
    ];
  };
}
