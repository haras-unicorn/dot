{ self, pkgs, ... }:

{
  # TODO: nushell may not be our preferred shell :/
  wayland.windowManager.hyprland.extraConfig = ''
    bind = super, t, exec, ${pkgs.kitty}/bin/kitty ${pkgs.nushell}/bin/nu
  '';

  imports = [
    # TODO: wayland ...
    # "${self}/src/module/home/cursor"

    # TODO: wayland ...
    # "${self}/src/module/home/brave"
    # "${self}/src/module/home/chromium"
    # "${self}/src/module/home/vivaldi"

    # TODO: recompilation ...
    # "${self}/src/module/home/librewolf"
    "${self}/src/module/home/firefox"

    "${self}/src/module/home/syncthing"
    "${self}/src/module/home/keepassxc"
    "${self}/src/module/home/ferdium"

    "${self}/src/module/home/ffmpeg"

    "${self}/src/module/home/spacedrive"

    "${self}/src/module/home/spotify"

    "${self}/src/module/home/kitty"
    "${self}/src/module/home/code"
    "${self}/src/module/home/lapce"

    "${self}/src/module/home/daw"
  ];

  home.packages = with pkgs; [
    feh
    mpv
    vlc
    libreoffice-fresh
    nomacs
    pinta
    dbeaver
    angryipscanner
  ];

  services.udiskie.enable = true;
  services.network-manager-applet.enable = true;
}
