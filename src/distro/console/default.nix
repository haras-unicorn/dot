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
    "${self}/src/module/gpg"
    "${self}/src/module/ssh"
    "${self}/src/module/cloud"

    "${self}/src/module/direnv"
    "${self}/src/module/starship"
    "${self}/src/module/zoxide"
    "${self}/src/module/pandoc"

    "${self}/src/module/yazi"
    "${self}/src/module/git"

    "${self}/src/module/piper"
    "${self}/src/module/llama-cpp"

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
    home.shared = {
      shell.aliases = {
        sis = editor;
      };

      home.packages = with pkgs; [
        cmatrix # NOTE: matrix in console
        file # NOTE: get file info
        zip # NOTE: zip stuff
        unzip # NOTE: unzip stuff
        unrar # NOTE: unrar stuff
        p7zip # NOTE: 7zip stuff
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
        postgresql_jit # NOTE: connect to postgresql
        watchexec # NOTE: run something when files change
        wget # NOTE: download things but often needed for other programs
        nmap # NOTE: network discovery
        mdadm # NOTE: RAID management
        mermaid-cli # NOTE: generate diagrams from text
        glow # NOTE: render markdown in terminal
        nixos-generators # NOTE: collection of generators to create nixos images
      ];
    };
  };
}
