{ pkgs, ... }:

let
  whisper-cpp = pkgs.openai-whisper-cpp;
in
{
  home = {
    home.packages = [
      whisper-cpp
    ];
  };
}
