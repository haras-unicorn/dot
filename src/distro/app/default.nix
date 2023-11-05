{ self, pkgs, config, ... }:

let
  term = "${pkgs."${config.term.pkg}"}/bin/${config.term.bin}";
  shell = "${pkgs."${config.user.shell.pkg}"}/bin/${config.user.shell.bin}";
in
{
  wayland.windowManager.hyprland.extraConfig = "bind = super, t, exec, ${term} ${shell}";

  services.udiskie.enable = true;
  services.network-manager-applet.enable = true;

  home.packages = with pkgs; [
    feh
    mpv
    libreoffice-fresh
    nomacs
    pinta
    dbeaver
    angryipscanner
  ];

  imports = [
    "${self}/src/module/home/syncthing"
    "${self}/src/module/home/keepassxc"
    "${self}/src/module/home/ferdium"

    "${self}/src/module/home/ffmpeg"
    "${self}/src/module/home/vlc"
    "${self}/src/module/home/spotify"
    "${self}/src/module/home/daw"

    # TODO: fix infinite recursion
    # "${self}/src/module/home/${config.term.module}"
    # "${self}/src/module/home/${config.visual.module}"
    # "${self}/src/module/home/${config.browser.module}"
    "${self}/src/module/home/kitty"
    "${self}/src/module/home/code"
    "${self}/src/module/home/firefox"
  ];
}
