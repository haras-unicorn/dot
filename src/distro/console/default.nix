{ self
, pkgs
, config
, ...
}:

# FIXME: fix infinite recursion

# TODO: https://github.com/mitsuhiko/systemfd

let
  editor = "${pkgs."${config.dot.editor.pkg}"}/bin/${config.dot.editor.bin}";
in
{
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
    pandoc # NOTE: document converter
    dasel # NOTE: json, yaml, toml, csv, etc manipulation
    jq # NOTE: popular json query language
    pastel # NOTE: color manipulation
    kalker # NOTE: math
    xh # NOTE: requests
    rnr # NOTE: recursive renaming
    hyperfine # NOTE: cli benchmarking
    fastmod # NOTE: large scale code refactoring
    usql # NOTE: connect to any db
    watchexec # NOTE: run something when files change
    wget # NOTE: download things but often needed for other programs
  ];

  imports = [
    "${self}/src/module/home/sh"

    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"
    "${self}/src/module/home/cloud"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"

    "${self}/src/module/home/yazi"
    "${self}/src/module/home/git"

    "${self}/src/module/home/yai"
    "${self}/src/module/home/tealdeer"

    # "${self}/src/module/home/${config.dot.shell.module}"
    # "${self}/src/module/home/${config.dot.editor.module}"
    "${self}/src/module/home/nushell"
    "${self}/src/module/home/helix"
  ];
}
