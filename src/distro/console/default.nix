{ self, pkgs, config, ... }:

{
  home.packages = with pkgs; [
    file
    unzip
    unrar
    pastel
    jq
    yq
  ];

  imports = [
    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"
    "${self}/src/module/home/${config.user.shell.module}"

    "${self}/src/module/home/yazi"
    "${self}/src/module/home/git"
    "${self}/src/module/home/${config.editor.module}"

    "${self}/src/module/home/open-interpreter"
    "${self}/src/module/home/aichat"
  ];
}
