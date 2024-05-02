{ self, lib, pkgs, config, ... }:

# FIXME: rpi-imager https://github.com/hyprwm/Hyprland/issues/4614

# TODO: firmware tui as part of diag
# TODO: https://github.com/NixOS/nixpkgs/issues/232266

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
with lib;
{
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
    "${self}/src/module/home/spotify"

    "${self}/src/module/home/chromium" # NOTE: for dev
    "${self}/src/module/home/librewolf" # NOTE: for dev
    # "${self}/src/module/home/teams"
    # "${self}/src/module/home/jetbrains"

    "${self}/src/module/home/kitty"
    "${self}/src/module/home/code"
    "${self}/src/module/home/firefox"
  ];

  options.dot = {
    term = {
      pkg = mkOption {
        type = with types; str;
        default = "kitty";
        example = "alacritty";
      };
      bin = mkOption {
        type = with types; str;
        default = "kitty";
        example = "alacritty";
      };
      module = mkOption {
        type = with types; str;
        default = "kitty";
        example = "alacritty";
      };
    };
    visual = {
      pkg = mkOption {
        type = with types; str;
        default = "vscode";
        example = "vscodium";
      };
      bin = mkOption {
        type = with types; str;
        default = "code";
        example = "codium";
      };
      module = mkOption {
        type = with types; str;
        default = "code";
        example = "code";
      };
    };
    browser = {
      pkg = mkOption {
        type = with types; str;
        default = "firefox";
        example = "vivaldi";
      };
      bin = mkOption {
        type = with types; str;
        default = "firefox";
        example = "vivaldi";
      };
      module = mkOption {
        type = with types; str;
        default = "firefox";
        example = "vivaldi";
      };
    };
  };

  config = {
    home.shared = {
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
        EDITOR = "${editor}";
      };

      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;

      home.packages = with pkgs; [
        rpi-imager # NOTE: make images for raspberry pi
        gnome-firmware # NOTE: view firmware 
        feh # NOTE: image viewer
        mpv # NOTE: video viewer
        pinta # NOTE: image manipulation
        dbeaver # NOTE: db viewer
        angryipscanner # NOTE: network scanner
        via # NOTE: keyboard configurator
        polychromatic # NOTE: razer device configurator
        netflix # NOTE: video streaming
        gimp # NOTE: image manipulation
        inkscape # NOTE: vector graphics design
        gpt4all # NOTE: run llms locally
        pencil # NOTE: UI/UX prototyping
        libresprite # NOTE: pixel art
      ];
    };
  };
}
