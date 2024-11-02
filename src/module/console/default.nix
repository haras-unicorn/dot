{ pkgs, lib, config, ... }:

let
  editor = "${config.dot.editor.package}/bin/${config.dot.editor.bin}";

  run = pkgs.writeShellApplication {
    name = "run";
    text = ''
      "$@" &>/dev/null & disown %-
    '';
  };

  repeat = pkgs.writeShellApplication {
    name = "repeat";
    text = ''
      while true; do "$@"; done
    '';
  };
in
{
  options.dot = {
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
  };

  config = {
    shared.dot = {
      shell.aliases = {
        pls = "sudo";
        rm = "rm -i";
        mv = "mv -i";
        yas = "yes";
        sis = editor;
      };
    };

    home = {
      home.packages = with pkgs; [
        run
        repeat
        htop
        man-pages
        man-pages-posix
      ];
    };
  };
}
