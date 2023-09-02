{ pkgs, ... }:

{
  imports = [
    ../../module/brave/brave.nix
    ../../module/dunst/dunst.nix
    ../../module/qtile/qtile.nix
    ../../module/redshift/redshift.nix
    ../../module/rofi/rofi.nix
    ../../module/sdui/sdui.nix
    ../../module/spotify/spotify.nix
    ../../module/tui/tui.nix
    ../../module/wallpaper/wallpaper.nix
  ];

  home.sessionVariables = {
    # TODO: not working cuz nushell?
    QT_QPA_PLATFORMTHEME = "gtk2";
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
  services.betterlockscreen.enable = true;
  services.network-manager-applet.enable = true;
  services.playerctld.enable = true;

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
