{ pkgs, ... }:

# TODO: config and use when more stable
# hopefully a vscode replacement

{
  home.packages = with pkgs; [ lapce ];
}
