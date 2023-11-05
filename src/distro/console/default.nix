{ self
, pkgs
, config
, ...
}:

let
  editor = "${pkgs."${config.dot.editor.pkg}"}/bin/${config.dot.editor.bin}";
in
{
  home.packages = with pkgs; [
    file
    zip
    unzip
    unrar
    p7zip
    pastel
    jq
    yq
  ];

  de.sessionVariables = {
    EDITOR = editor;
  };

  shell.aliases = {
    sis = editor;
  };

  imports = [
    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"
    # TODO: fix infinite recursion
    # "${self}/src/module/home/${config.dot.user.shell.module}"
    "${self}/src/module/home/nushell"

    "${self}/src/module/home/yazi"
    "${self}/src/module/home/git"
    # TODO: fix infinite recursion
    # "${self}/src/module/home/${config.dot.editor.module}"
    "${self}/src/module/home/helix"

    "${self}/src/module/home/open-interpreter"
    "${self}/src/module/home/aichat"
  ];
}
