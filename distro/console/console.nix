{ pkgs, ... }:

{
  imports = [
    ../../module/home/git/git.nix
    ../../module/home/helix/helix.nix
    ../../module/home/nushell/nushell.nix
    ../../module/home/starship/starship.nix
    ../../module/home/zoxide/zoxide.nix
    ../../module/home/bat/bat.nix
    ../../module/home/ripgrep/ripgrep.nix
    ../../module/home/exa/exa.nix
  ];

  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  home.shellAliases = {
    pls = "sudo";
    rm = "rm -i";
    mv = "mv -i";
    yas = "yes";
  };
  home.packages = with pkgs; [
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
