{ ... }:

{
  home.shared = {
    programs.gpg.enable = true;
    services.gpg-agent.enable = true;
  };
}
