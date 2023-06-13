{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.username = "virtuoso";
  home.homeDirectory = "/home/virtuoso";
  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk2";
  };
  home.packages = with pkgs; [
    nil
    ferdium
    keepassxc
    brave
    python311Packages.adblock
  ];
  home.shellAliases = {
    lg = "lazygit";
  };

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

  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess= false;
    gui = {
      showIcons = true;
    };
  };

  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
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

  home.stateVersion = "23.11";

  # TODO: when it gets better use it
  # programs.mpv.enable = true;
  # programs.qutebrowser.enable = true;
  # programs.qutebrowser.searchEngines = {
  #   "DEFAULT" = "https://google.com/search?hl=en&q={}";
  #   "g" = "https://google.com/search?hl=en&q={}";
  # };
  # programs.qutebrowser.keyBindings = {
  #   normal = {
  #     ",m" = "spawn mpv {url}";
  #     ",M" = "hint links spawn mpv {hint-url}";
  #   };
  # };
  # home.file.".local/share/qutebrowser/greasemonkey/youtubeBlocker.js".source =
  #   ../../assets/.local/share/qutebrowser/greasemonkey/youtubeBlocker.js;
  # programs.qutebrowser.settings = {
  #   auto_save.session = true;
  #   colors.webpage.darkmode.enabled = true;
  #   content.blocking.enabled = true;
  #   content.blocking.method = "adblock";
  #   content.fullscreen.window = true;
  #   content.geolocation = false;
  #   content.notifications.enabled = false;
  #   content.pdfjs = true;
  #   content.webrtc_ip_handling_policy = "default-public-interface-only";
  #   editor.command = [ "kitty" "hx" "{file}:{line}:{column}" ];
  #   fonts.default_family = "JetBrainsMono Nerd Font";
  #   scrolling.bar = "never";
  #   tabs.max_width = 200;
  #   url.default_page = "https://google.com";
  #   url.start_pages = "https://google.com";
  #   window.hide_decoration = true;
  #   window.transparent = true;
  #   zoom.default = "150%";
  #   zoom.text_only = true;
  #   # TODO: this is so bad...
  #   scrolling.smooth = true;
  #   # TODO: /usr/share/qutebrowser/scripts/dictcli.py install en-US ??
  #   spellcheck.languages = [
  #     "en-US"
  #     "hr-HR"
  #   ];
  #   # TODO: generates code with dot but supposed to generate dictionary constructor
  #   statusbar.padding = {
  #     left = 2;
  #     right = 2;
  #     top = 2;
  #     bottom = 2;
  #   };
  #   tabs.indicator.padding = {
  #     left = 2;
  #     right = 2;
  #     top = 2;
  #     bottom = 2;
  #   };
  #   tabs.padding = {
  #     left = 2;
  #     right = 2;
  #     top = 2;
  #     bottom = 2;
  #   };
  # };
}
