{ pkgs, ... }:

{
  imports = [
    ../../module/git/git.nix
    ../../module/helix/helix.nix
    ../../module/nushell/nushell.nix
    ../../module/starship/starship.nix
    ../../module/zoxide/zoxide.nix
    ../../module/bat/bat.nix
    ../../module/ripgrep/ripgrep.nix
    ../../module/exa/exa.nix
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
