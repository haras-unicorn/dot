{ self
, pkgs
, config
, ...
}:

# FIXME: fix infinite recursion

# TODO: doas or please sudo alternative

let
  editor = "${pkgs."${config.dot.editor.pkg}"}/bin/${config.dot.editor.bin}";
in
{
  home.packages = with pkgs; [
    file # NOTE: get file info
    zip # NOTE: zip stuff
    unzip # NOTE: unzip stuff
    unrar # NOTE: unrar stuff
    p7zip # NOTE: 7zip stuff
    parted # NOTE: partition manager
    pandoc # NOTE: document converter
    dasel # NOTE: json, yaml, toml, csv, etc manipulation
    pastel # NOTE: color manipulation
    eva # NOTE: math
    xh # NOTE: requests
    rnr # NOTE: recursive renaming
    hyperfine # NOTE: cli benchmarking
    tealdeer # NOTE: tldr <some-command> to learn basics
    fastmod # NOTE: large scale code refactoring
  ];

  de.sessionVariables = {
    EDITOR = editor;
  };

  shell.aliases = {
    sis = editor;
  };

  imports = [
    "${self}/src/module/home/sh"

    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"

    "${self}/src/module/home/yazi"
    "${self}/src/module/home/git"

    "${self}/src/module/home/yai"

    # "${self}/src/module/home/${config.dot.shell.module}"
    # "${self}/src/module/home/${config.dot.editor.module}"
    "${self}/src/module/home/nushell"
    "${self}/src/module/home/helix"
  ];
}
