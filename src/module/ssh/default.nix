{ ... }:

{
  home.shared = {
    programs.ssh.enable = true;
    services.ssh-agent.enable = true;
  };
}
