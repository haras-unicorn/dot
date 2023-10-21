{ pkgs, gnupg, ... }:

{
  home.packages = [
    pkgs."${gnupg.package}"
  ];

  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "${gnupg.flavor}";
}
