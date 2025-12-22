{ pkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      pkgs.whisper-cpp
    ];
  };
}
