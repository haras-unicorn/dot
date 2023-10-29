{ self, pkgs, ... }:

{
  imports = [
    # TODO: somehow on qt and hyprland??
    # "${self}/src/module/home/cursor/cursor.nix"
    "${self}/src/module/home/gtk/gtk.nix"
    "${self}/src/module/home/qt/qt.nix"
    "${self}/src/module/home/brave/brave.nix"
    "${self}/src/module/home/vivaldi/vivaldi.nix"
    "${self}/src/module/home/spotify/spotify.nix"
    "${self}/src/module/home/kitty/kitty.nix"
    "${self}/src/module/home/syncthing/syncthing.nix"
    "${self}/src/module/home/keepassxc/keepassxc.nix"
    "${self}/src/module/home/ferdium/ferdium.nix"
    "${self}/src/module/home/code/code.nix"
    "${self}/src/module/home/daw/daw.nix"
  ];

  home.packages = with pkgs; [
    emote
    libreoffice-fresh
    vlc
    nomacs
    pinta
    feh
    dbeaver
    angryipscanner
  ];

  services.udiskie.enable = true;
  services.network-manager-applet.enable = true;
}
