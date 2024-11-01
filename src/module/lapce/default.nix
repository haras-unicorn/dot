{ pkgs, ... }:

# TODO: config and use when more stable
# hopefully a vscode replacement

{
  home = {
    home.packages = with pkgs; [ lapce ];
  };
}
