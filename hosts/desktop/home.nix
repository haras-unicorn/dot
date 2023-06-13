{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.username = "virtuoso";
  home.homeDirectory = "/home/virtuoso";

  services.syncthing.enable = true;
  services.syncthing.tray.enable = true;

  programs.vim.enable = true;
  programs.vim.extraConfig = builtins.readFile ../../assets/.vimrc;

  programs.kitty.enable = true;
  programs.kitty.extraConfig = builtins.readFile ../../assets/.config/kitty/kitty.conf;

  programs.helix.enable = true;

  programs.nushell.enable = true;
  programs.nushell.extraConfig = ''
    let-env config = {
      show_banner: false
      edit_mode: vi
      cursor_shape: {
        vi_insert: line
        vi_normal: underscore
      }
    }
  '';
  programs.nushell.environmentVariables = {
    PROMPT_INDICATOR_VI_INSERT = "'i '";
    PROMPT_INDICATOR_VI_NORMAL = "'n '";
  };
  programs.starship.enable = true;
  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enable = true;
  programs.zoxide.enableNushellIntegration = true;
  home.file.".config/starship.toml".source = ../../assets/.config/starship/starship.toml;

  home.file.".config/qtile".source = ../../assets/.config/qtile;

  gtk.enable = true;
  gtk.font.package = pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; };
  gtk.font.name = "JetBrainsMono Nerd Font";
  gtk.iconTheme.name = "BeautyLine";
  gtk.iconTheme.package = pkgs.beauty-line-icon-theme;
  gtk.theme.name = "Sweet-Dark";
  gtk.theme.package = pkgs.sweet;
  qt.enable = true;
  qt.platformTheme = "gtk";
  qt.style.name = "Sweet-Dark";
  qt.style.package = pkgs.sweet;
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk2";
  };

  home.packages = with pkgs; [
    nil
  ];

  home.stateVersion = "23.11";
}
