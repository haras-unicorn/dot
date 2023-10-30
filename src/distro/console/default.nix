{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/gpg"
    "${self}/src/module/home/ssh"

    "${self}/src/module/home/git"

    "${self}/src/module/home/lf"

    "${self}/src/module/home/bat"
    "${self}/src/module/home/ripgrep"
    "${self}/src/module/home/eza"

    "${self}/src/module/home/direnv"
    "${self}/src/module/home/starship"
    "${self}/src/module/home/zoxide"

    # TODO: looks ugly
    # "${self}/src/module/home/fastfetch"
    # TODO: doesn't work
    # "${self}/src/module/home/mommy"
    "${self}/src/module/home/vivid"

    "${self}/src/module/home/nushell"

    "${self}/src/module/home/helix"
  ];

  home.packages = with pkgs; [
    man-pages
    man-pages-posix
    pciutils
    lsof
    dmidecode
    inxi
    hwinfo
    ncdu
    fd
    file
    duf
    unzip
    unrar
    sd
    htop
    lm_sensors
    pastel
    jq
    yq
    nvtop
    glxinfo
  ];

  home.shellAliases = {
    pls = "sudo";
    rm = "rm -i";
    mv = "mv -i";
    yas = "yes";
  };
}
