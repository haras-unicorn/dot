{ lib, pkgs, config, ... }:

# TODO: firmware tui as part of diag
# TODO: https://github.com/NixOS/nixpkgs/issues/232266
# TODO: use lib.getExe insead of the bin thing

let
  terminal = "${config.dot.terminal.package}/bin/${config.dot.terminal.bin}";
  shell = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
  browser = "${config.dot.browser.package}/bin/${config.dot.browser.bin}";
  visual = "${config.dot.visual.package}/bin/${config.dot.visual.bin}";
  editor = "${config.dot.editor.package}/bin/${config.dot.editor.bin}";

  browserDesktop = "${config.dot.browser.package}/share/applications/${config.dot.browser.bin}.desktop";
  browserMime = {
    "text/html" = browserDesktop;
    "x-scheme-handler/http" = browserDesktop;
    "x-scheme-handler/https" = browserDesktop;
  };

  visualDesktop = "${config.dot.visual.package}/share/applications/${config.dot.visual.bin}.desktop";
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
  options = {
    terminal = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.kitty;
        example = pkgs.alacritty;
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "kitty";
        example = "alacritty";
      };
      sessionVariables = lib.mkOption {
        type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
        default = { };
        example = { EDITOR = "hx"; };
        description = ''
          Environment variables to set with kitty.
        '';
      };
    };
    visual = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vscode;
        example = pkgs.vscodium;
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "code";
        example = "codium";
      };
    };
    browser = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.firefox-bin;
        example = pkgs.vivaldi;
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "firefox";
        example = "vivaldi";
      };
    };
  };

  config = {
    shared = {
      dot = {
        desktopEnvironment.keybinds = [
          {
            mods = [ "super" ];
            key = "t";
            command = "${terminal} ${shell}";
          }
          {
            mods = [ "super" ];
            key = "w";
            command = "${browser}";
          }
        ];

        desktopEnvironment.sessionVariables = {
          VISUAL = "${visual}";
          BROWSER = "${browser}";
          EDITOR = "${editor}";
        };
      };
    };

    home = {
      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;

      home.packages = with pkgs; [
        pinta # NOTE: image manipulation
        netflix # NOTE: video streaming
        gimp # NOTE: image manipulation
        inkscape # NOTE: vector graphics design
        pencil # NOTE: UI/UX prototyping
      ];
    };
  };
}