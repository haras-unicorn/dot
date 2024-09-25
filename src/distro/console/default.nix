{ self
, pkgs
, lib
, config
, ...
}:

# TODO: systemfd + watchexec for hot reload with anything

let
  editor = "${config.dot.editor.package}/bin/${config.dot.editor.bin}";
in
{
  imports = [
    "${self}/src/module/stdrename"

    "${self}/src/module/pinentry"
    "${self}/src/module/gpg"
    "${self}/src/module/ssh"
    "${self}/src/module/cloud"

    "${self}/src/module/direnv"
    "${self}/src/module/starship"
    "${self}/src/module/zoxide"
    "${self}/src/module/pandoc"

    "${self}/src/module/yazi"
    "${self}/src/module/git"

    "${self}/src/module/yai"
    "${self}/src/module/tealdeer"

    # Shells
    "${self}/src/module/nushell"
    "${self}/src/module/bash"

    # Editors
    "${self}/src/module/helix"
  ];

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
    shared = {
      dot = {
        shell.aliases = {
          sis = editor;
        };
      };
    };

    home.shared = {
      home.packages = with pkgs; [
        inetutils # NOTE: Common network programs
        ouch # NOTE: only compression/decompression tool you will ever need
        skim # NOTE: fzf
        monolith # NOTE: entire page to one html file
        parted # NOTE: partition manager
        dasel # NOTE: json, yaml, toml, csv, etc manipulation
        jq # NOTE: popular json manipulator
        yq-go # NOTE: json, yaml, toml, csv, etc manipulation
        pastel # NOTE: color manipulation
        kalker # NOTE: math
        xh # NOTE: requests
        rnr # NOTE: recursive renaming
        hyperfine # NOTE: cli benchmarking
        fastmod # NOTE: large scale code refactoring
        usql # NOTE: connect to any db
        postgresql # NOTE: connect to postgresql
        watchexec # NOTE: run something when files change
        wget # NOTE: download things but often needed for other programs
        nmap # NOTE: network discovery
        mdadm # NOTE: RAID management
        mermaid-cli # NOTE: generate diagrams from text
        glow # NOTE: render markdown in terminal
        nixos-generators # NOTE: collection of generators to create nixos images
        dos2unix # NOTE: convert Windows file endings to Unix
        unixtools.xxd # NOTE: make hexdump
        github-copilot-cli # NOTE: CLI AI help
        rustscan # NOTE: ip scanner
        marimo # NOTE: next-gen python notebook
      ];
    };
  };
}
