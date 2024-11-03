{ lib, pkgs, config, ... }:

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
    shell = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.bashInteractive;
        example = pkgs.nushell;
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "bash";
        example = "nu";
      };
      sessionVariables = lib.mkOption {
        type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
        default = { };
        example = { EDITOR = "hx"; };
        description = ''
          Environment variables to set on session start with Nushell.
        '';
      };
      aliases = lib.mkOption {
        type = with lib.types; lazyAttrsOf str;
        default = { };
        example = { rm = "rm -i"; };
        description = ''
          Aliases to use in Nushell.
        '';
      };
      sessionStartup = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "fastfetch" ];
        description = ''
          Commands to execute on session start with Nushell.
        '';
      };
    };
    editor = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.vim;
        example = pkgs.helix;
      };
      bin = lib.mkOption {
        type = lib.types.str;
        default = "vim";
        example = "hx";
      };
    };
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
        shell = { package = pkgs.nushell; bin = "nu"; };
        editor = { package = pkgs.helix; bin = "hx"; };
        visual = { package = pkgs.vscode; bin = "code"; };
        terminal = { package = pkgs.kitty; bin = "kitty"; };
        browser = { package = pkgs.firefox-bin; bin = "firefox"; };

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

      home.packages = [
        pkgs.xdg-user-dirs
        pkgs.xdg-utils
        pkgs.shared-mime-info
      ];

      xdg.enable = true;

      xdg.userDirs.enable = true;
      xdg.userDirs.createDirectories = true;

      xdg.userDirs.desktop = "${config.home.homeDirectory}/desktop";
      xdg.userDirs.download = "${config.home.homeDirectory}/download";

      xdg.userDirs.music = "${config.home.homeDirectory}/music";
      xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
      xdg.userDirs.videos = "${config.home.homeDirectory}/videos";

      xdg.userDirs.templates = "${config.home.homeDirectory}/templates";
      xdg.userDirs.documents = "${config.home.homeDirectory}/documents";

      xdg.userDirs.publicShare = "${config.home.homeDirectory}/public";

      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
    };
  };
}