{ pkgs, ... }:

let
  username = "virtuoso";
in
{
  programs.home-manager.enable = true;

  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
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
    nixpkgs-fmt

    # tui
    ncdu
    xclip
    spotify-tui
    feh
    lazydocker

    # services
    keepmenu
    brightnessctl
    gnome.seahorse

    # apps
    ferdium
    keepassxc
    brave
  ];

  # dev
  programs.git.enable = true;
  programs.helix.enable = true;
  programs.helix.settings = {
    editor = {
      auto-format = true;
    };
  };
  programs.helix.languages = {
    language = [
      {
        name = "python";
        auto-format = true;
        formatter = { command = "black"; };
      }
      {
        name = "nix";
        auto-format = true;
        formatter = { command = "nixpkgs-fmt"; };
      }
    ];
  };

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
  home.file.".config/starship.toml".source = ../../assets/.config/starship/starship.toml;
  programs.zoxide.enable = true;
  programs.zoxide.enableNushellIntegration = true;
  programs.lazygit.enable = true;
  programs.lazygit.settings = {
    notARepository = "quit";
    promptToReturnFromSubprocess = false;
    gui = {
      showIcons = true;
    };
  };
  programs.htop.enable = true;

  # services
  services.gnome-keyring.enable = true;
  programs.ssh.enable = true;
  programs.ssh.matchBlocks = {
    "github.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/keys/personal";
    };
    "gitlab.com" = {
      user = "git";
      identityFile = "/home/${username}/.ssh/keys/personal";
    };
  };
  services.syncthing.enable = true;
  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.redshift.enable = true;
  services.redshift.provider = "geoclue2";
  services.network-manager-applet.enable = true;
  services.dunst.enable = true;
  # home.file.".config/dunst".source = ../../assets/.config/dunst;
  programs.rofi.enable = true;
  # home.file.".config/rofi".source = ../../assets/.config/rofi;
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  services.betterlockscreen.enable = true;
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override { withKeyring = true; };
  services.spotifyd.settings = {
    global = {
      username = "ftsedf157kfova8yuzoq1dfax";
      use_keyring = true;
      use_mpris = true;
      backend = "pulseaudio";
      device_name = "${username}";
      bitrate = 320;
      cache_path = "/home/${username}/.cache/spotifyd";
      volume_normalisation = true;
      device_type = "computer";
    };
  };
  services.playerctld.enable = true;
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
