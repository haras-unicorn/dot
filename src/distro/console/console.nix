{ self, pkgs, ... }:

{
  imports = [
    "${self}/src/module/home/git/git.nix"
    "${self}/src/module/home/helix/helix.nix"
    "${self}/src/module/home/nushell/nushell.nix"
    "${self}/src/module/home/starship/starship.nix"
    "${self}/src/module/home/zoxide/zoxide.nix"
    "${self}/src/module/home/bat/bat.nix"
    "${self}/src/module/home/ripgrep/ripgrep.nix"
    "${self}/src/module/home/exa/exa.nix"
  ];

  home.packages = with pkgs; [
    pinentry
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
  ];

  programs.htop.enable = true;
  programs.lf.enable = true;

  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
  programs.ssh.enable = true;
  services.ssh-agent.enable = true;
}
