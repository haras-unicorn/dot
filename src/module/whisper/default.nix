{ pkgs, ... }:

let
  whisper-cpp = pkgs.openai-whisper-cpp;
in
{
  home.shared = {
    home.packages = [
      whisper-cpp
    ];
  };
}
