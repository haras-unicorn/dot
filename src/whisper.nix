{ pkgs, ... }:

{
  branch.homeManagerModule.homeManagerModule = {
    home.packages = [
      pkgs.openai-whisper-cpp
    ];
  };
}
