{ self, pkgs, config, ... }:

let
  term = "${pkgs."${config.dot.term.pkg}"}/bin/${config.dot.term.bin}";
  shell = "${pkgs."${config.dot.user.shell.pkg}"}/bin/${config.dot.user.shell.bin}";
  browser = "${pkgs."${config.dot.browser.pkg}"}/bin/${config.dot.browser.bin}";
  visual = "${pkgs."${config.dot.visual.pkg}"}/bin/${config.dot.visual.bin}";
in
{
  de.keybinds = [
    {
      mods = [ "super" ];
      key = "t";
      command = "${term} ${shell}";
    }
    {
      mods = [ "super" ];
      key = "w";
      command = "${browser}";
    }
  ];

  de.sessionVariables = {
    VISUAL = "${visual}";
    BROWSER = "${browser}";
  };

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
