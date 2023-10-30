{ pkgs, config, ... }:

{
  home.packages = [
    pkgs."${config.dot.gpg.pkg}"
  ];

  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "${config.dot.gpg.flavor}";
}
