{ pkgs, ... }:

{
  imports = [
    ../../modules/git/git.nix
    ../../modules/helix/helix.nix
    ../../modules/nushell/nushell.nix
    ../../modules/starship/starship.nix
    ../../modules/zoxide/zoxide.nix
    ../../modules/bat/bat.nix
    ../../modules/ripgrep/ripgrep.nix
    ../../modules/exa/exa.nix
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
    # tui
    pciutils
    lsof
    dmidecode
    inxi
    hwinfo
    ncdu
    xclip
    fd
    file
    duf
    unzip
    unrar
    sd
  ];

  # dev

  # tui
  programs.htop.enable = true;
  programs.lf.enable = true;

  # services
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
  programs.ssh.enable = true;

  home.stateVersion = "23.11";
}
