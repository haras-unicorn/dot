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
  home.file.".config/nushell/config.nu".source = ../../assets/.config/nushell/config.nu;
  home.file.".config/nushell/env.nu".source = ../../assets/.config/nushell/env.nu;
  home.file.".config/starship/starship.toml".source = ../../assets/.config/starship/starship.toml;

  home.stateVersion = "23.11";
}
