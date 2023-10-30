{ pkgs, ... }:

# TODO: lowercase directories + check that all programs work with that

{
  home.packages = with pkgs; [
    xdg-user-dirs
  ];

  xdg.userDirs.createDirectories = true;
}
