{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.username = "virtuoso";
  home.homeDirectory = "/home/virtuoso";

  services.syncthing.enable = true;
  services.syncthing.tray.enable = true;

  programs.vim.enable = true;
  programs.vim.extraConfig = builtins.readFile ../../assets/.vimrc;

  home.file.".config/qtile".source = ../../assets/.config/qtile;

  home.stateVersion = "23.11";
}
