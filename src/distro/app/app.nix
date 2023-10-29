{ self, pkgs, ... }:

{
  # TODO: nushell may not be our preferred shell :/
  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty ${pkgs.nushell}/bin/nu
  '';

  imports = [
    # TODO: wayland ...
    # "${self}/src/module/home/cursor/cursor.nix"

    # TODO: wayland/gpu flags in appropriate places
    # NOTE: problem is that gpu and wayland/x11 are system wide
    # "${self}/src/module/home/brave/brave.nix"
    # "${self}/src/module/home/chromium/chromium.nix"
    "${self}/src/module/home/vivaldi/vivaldi.nix"
    "${self}/src/module/home/librewolf/librewolf.nix"

    "${self}/src/module/home/syncthing/syncthing.nix"
    "${self}/src/module/home/keepassxc/keepassxc.nix"
    "${self}/src/module/home/ferdium/ferdium.nix"

    "${self}/src/module/home/spotify/spotify.nix"

    "${self}/src/module/home/kitty/kitty.nix"
    "${self}/src/module/home/code/code.nix"

    "${self}/src/module/home/daw/daw.nix"
  ];

  home.packages = with pkgs; [
    feh
    mpv
    libreoffice-fresh
    vlc
    nomacs
    pinta
    dbeaver
    angryipscanner
  ];

  services.udiskie.enable = true;
  services.network-manager-applet.enable = true;
}
