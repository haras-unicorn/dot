{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pinentry
  ];

  programs.gpg.enable = true;
  services.gpg-agent.enable = true;
  services.gpg-agent.pinentryFlavor = "tty";
}
