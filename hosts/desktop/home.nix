{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.username = "virtuoso";
  home.homeDirectory = "/home/virtuoso";
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk2";
  };
  home.shellAliases = {
    lg = "lazygit";
  };
  home.packages = with pkgs; [
    # dev
    python311Packages.python-lsp-server
    nil

    # tui
    ncdu
    xclip

    # services
    keepmenu

    # apps
    ferdium
    keepassxc
    brave
  ];

  # dev
  programs.git.enable = true;
  programs.helix.enable = true;
  
  # tui
  programs.kitty.enable = true;
  programs.kitty.extraConfig = builtins.readFile ../../assets/.config/kitty/kitty.conf;
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
  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess= false;
    gui = {
      showIcons = true;
    };
  };

  # services
  services.syncthing.enable = true;
  services.syncthing.tray.enable = true;
  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.redshift.enable = true;
  services.redshift.provider = "geoclue2";
  services.network-manager-applet.enable = true;
  services.dunst.enable = true;
  programs.rofi.enable = true;
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
  home.file.".config/qtile".source = ../../assets/.config/qtile;

  # theming
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

  home.stateVersion = "23.11";
}
