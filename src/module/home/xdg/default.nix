{ pkgs, ... }:

# TODO: lowercase directories + check that all programs work with that

{
  home.packages = with pkgs; [
    xdg-user-dirs
    xdg-utils
  ];

  xdg.userDirs.createDirectories = true;
  xdg.mimeApps.enable = true;
}
