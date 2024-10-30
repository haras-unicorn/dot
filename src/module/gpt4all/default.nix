{ pkgs, ... }:

{
  home.shared = {
    home.packages = [
      pkgs.gpt4all
    ];
  };
}
