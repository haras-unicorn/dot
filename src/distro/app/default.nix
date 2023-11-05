{ self, pkgs, config, ... }:

let
  term = "${pkgs."${config.dot.term.pkg}"}/bin/${config.dot.term.bin}";
  shell = "${pkgs."${config.dot.user.shell.pkg}"}/bin/${config.dot.user.shell.bin}";
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
    # "${self}/src/module/home/${config.dot.term.module}"
    # "${self}/src/module/home/${config.dot.visual.module}"
    # "${self}/src/module/home/${config.dot.browser.module}"
    "${self}/src/module/home/kitty"
    "${self}/src/module/home/code"
    "${self}/src/module/home/firefox"
  ];
}
