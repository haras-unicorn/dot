{ pkgs, ... }:

{
  imports = [
    ../../modules/git/git.nix
    ../../modules/helix/helix.nix
    ../../modules/nushell/nushell.nix
    ../../modules/starship/starship.nix
    ../../modules/zoxide/zoxide.nix
    ../../modules/bat/bat.nix
  ];

  programs.starship.enableNushellIntegration = true;
  programs.zoxide.enableNushellIntegration = true;

  home.shellAliases = {
    grep = "rg";
    la = "exa";

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
  programs.ripgrep.enable = true;
  programs.ripgrep.arguments = [
    "--max-columns=100"
    "--max-columns-preview"
    "--colors=auto"
    "--smart-case"
  ];
  programs.exa.enable = true;
  programs.exa.extraOptions = [
    "--all"
    "--list"
    "--color=always"
    "--group-directories-first"
    "--icons"
    "--group"
    "--header"
  ];

  # services
  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
  programs.ssh.enable = true;

  home.stateVersion = "23.11";
}
