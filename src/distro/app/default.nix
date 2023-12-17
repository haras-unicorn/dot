{ self, pkgs, config, ... }:

# FIXME: fix infinite recursion

# TODO: firmware tui as part of diag

let
  term = "${pkgs."${config.dot.term.pkg}"}/bin/${config.dot.term.bin}";
  shell = "${pkgs."${config.dot.shell.pkg}"}/bin/${config.dot.shell.bin}";
  browser = "${pkgs."${config.dot.browser.pkg}"}/bin/${config.dot.browser.bin}";
  visual = "${pkgs."${config.dot.visual.pkg}"}/bin/${config.dot.visual.bin}";
  editor = "${pkgs."${config.dot.editor.pkg}"}/bin/${config.dot.editor.bin}";

  browserDesktop = "${pkgs."${config.dot.browser.pkg}"}/share/applications/${config.dot.browser.bin}.desktop";
  browserMime = {
    "text/html" = browserDesktop;
    "x-scheme-handler/http" = browserDesktop;
    "x-scheme-handler/https" = browserDesktop;
  };


  visualDesktop = "${pkgs."${config.dot.visual.pkg}"}/share/applications/${config.dot.visual.bin}.desktop";
  visualMime = {
    "text/css" = visualDesktop;
    "application/javascript" = visualDesktop;
    "application/json" = visualDesktop;
    "application/x-sh" = visualDesktop;
    "application/xhtml+xml" = visualDesktop;
    "application/xml" = visualDesktop;
  };

  mime = browserMime // visualMime;
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
    EDITOR = editor;
  };

  xdg.mimeApps.associations.added = mime;
  xdg.mimeApps.defaultApplications = mime;

  home.packages = with pkgs; [
    gnome-firmware # NOTE: view firmware 
    feh # NOTE: image viewer
    mpv # NOTE: video viewer
    pinta # NOTE: image manipulation
    dbeaver # NOTE: db viewer
    angryipscanner # NOTE: network scanner
    via # NOTE: keyboard configurator
    spotify # NOTE: music streaming
    netflix # NOTE: video streaming
  ];

  imports = [
    "${self}/src/module/home/syncthing"
    "${self}/src/module/home/keepassxc"
    "${self}/src/module/home/ferdium"

    "${self}/src/module/home/ffmpeg"
    "${self}/src/module/home/vlc"
    "${self}/src/module/home/udiskie"
    "${self}/src/module/home/nm-applet"
    "${self}/src/module/home/libreoffice"
    "${self}/src/module/home/nomacs"
    "${self}/src/module/home/okular"
    "${self}/src/module/home/xarchiver"
    "${self}/src/module/home/discord"

    "${self}/src/module/home/chromium" # NOTE: for dev
    "${self}/src/module/home/librewolf" # NOTE: for dev

    # "${self}/src/module/home/${config.dot.term.module}"
    # "${self}/src/module/home/${config.dot.visual.module}"
    # "${self}/src/module/home/${config.dot.browser.module}"
    "${self}/src/module/home/kitty"
    "${self}/src/module/home/code"
    "${self}/src/module/home/firefox"
  ];
}
