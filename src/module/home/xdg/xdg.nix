{ pkgs, ... }:

{
  home.packages = with pkgs; [
    xdg-user-dirs
  ];

  xdg.userDirs.createDirectories = true;
}
