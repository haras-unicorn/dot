{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/qtile/qtile.nix"
    "${self}/src/module/home/dunst/dunst.nix"
    "${self}/src/module/home/redshift/redshift.nix"
    "${self}/src/module/home/rofi/rofi.nix"
    "${self}/src/module/home/wallpaper/wallpaper.nix"
    "${self}/src/module/home/gtk/gtk.nix"
    "${self}/src/module/home/qt/qt.nix"
    "${self}/src/module/home/brave/brave.nix"
    "${self}/src/module/home/spotify/spotify.nix"
    "${self}/src/module/home/kitty/kitty.nix"
    "${self}/src/module/home/syncthing/syncthing.nix"
    "${self}/src/module/home/sdui/sdui.nix"
    "${self}/src/module/home/tui/tui.nix"
  ];

  home.packages = with pkgs; [
    brightnessctl
    lazydocker
    ferdium
    keepassxc
    emote
    libreoffice-fresh
    obs-studio
    shotwell
    pinta
  ];

  programs.feh.enable = true;
  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.betterlockscreen.enable = true;
  services.network-manager-applet.enable = true;
  services.playerctld.enable = true;
}
