{ pkgs, ... }:

{
  home = {
    shared = {
      home.packages = with pkgs; [
        aider-chat
      ];
    };
  };
}
