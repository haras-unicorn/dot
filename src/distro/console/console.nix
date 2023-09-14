{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/gpg/gpg.nix"
    "${self}/src/module/home/ssh/ssh.nix"
    "${self}/src/module/home/git/git.nix"
    "${self}/src/module/home/lf/lf.nix"
    "${self}/src/module/home/helix/helix.nix"
    "${self}/src/module/home/nushell/nushell.nix"
    "${self}/src/module/home/starship/starship.nix"
    "${self}/src/module/home/zoxide/zoxide.nix"
    "${self}/src/module/home/bat/bat.nix"
    "${self}/src/module/home/ripgrep/ripgrep.nix"
    "${self}/src/module/home/eza/eza.nix"
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
  ];
}
