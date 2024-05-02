{ self
, pkgs
, config
, ...
}:

# TODO: systemfd + watchexec for hot reload with anything

let
  editor = "${pkgs."${config.dot.editor.pkg}"}/bin/${config.dot.editor.bin}";
in
{
  imports = [
    "${self}/src/module/home/sh"

    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"
    "${self}/src/module/home/cloud"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"
    "${self}/src/module/home/pandoc"

    "${self}/src/module/home/yazi"
    "${self}/src/module/home/git"

    "${self}/src/module/home/piper"
    "${self}/src/module/home/llama-cpp"

    "${self}/src/module/home/yai"
    "${self}/src/module/home/tealdeer"

    "${self}/src/module/home/nushell"
    "${self}/src/module/home/helix"
  ];

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
}
