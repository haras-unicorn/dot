{ pkgs, config, ... }:

{
  home.sessionVariables = {
    # TODO: not working cuz nushell?
    QT_QPA_PLATFORMTHEME = "gtk2";
    BROWSER = "brave";
  };

  home.packages = with pkgs; [
    xclip
    woeusb
    lazydocker
    spotify-tui

    keepmenu
    brightnessctl
    ntfs3g

    ferdium
    keepassxc
    brave
    emote
    libreoffice-fresh
    obs-studio
    shotwell
    pinta
  ];

  programs.feh.enable = true;
  services.syncthing.enable = true;
  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.redshift.enable = true;
  services.redshift.provider = "geoclue2";
  services.network-manager-applet.enable = true;
  xdg.configFile."keepmenu/config.ini".source = ../../assets/.config/keepmenu/config.ini;
  services.random-background.enable = true;
  services.random-background.imageDirectory = "%h/.local/share/wallpapers";
  services.betterlockscreen.enable = true;
  home.file.".local/share/wallpapers".source = ../../assets/.local/share/wallpapers;
  services.spotifyd.enable = true;
  services.spotifyd.package = pkgs.spotifyd.override { withKeyring = true; };
  # security add-generic-password -s spotifyd -D rust-keyring -a <your username> -w
  services.spotifyd.settings = {
    global = {
      username = "ftsedf157kfova8yuzoq1dfax";
      use_keyring = true;
      use_mpris = true;
      dbus_type = "session";
      backend = "pulseaudio";
      bitrate = 320;
      cache_path = "${config.xdg.cacheHome}/spotifyd";
      volume_normalisation = true;
      device_type = "computer";
      device_name = "${config.networking.hostName}";
      zeroconf_port = 8888;
    };
  };
  services.playerctld.enable = true;
  xdg.configFile."qtile".source = ../../assets/.config/qtile;

  fonts.fontconfig.enable = true;
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
}
