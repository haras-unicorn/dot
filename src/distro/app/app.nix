{ self, pkgs, ... }:

{
  imports = [
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
    emote
    brightnessctl
    ferdium
    keepassxc
    libreoffice-fresh
    obs-studio
    shotwell
    pinta
  ];

  services.udiskie.enable = true;
  services.flameshot.enable = true;
  services.betterlockscreen.enable = true;
  services.network-manager-applet.enable = true;
}
