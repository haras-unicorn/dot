{ ... }:

{
  integrate.homeManagerModule.homeManagerModule = {
    programs.ssh.enable = true;
    services.ssh-agent.enable = true;
  };
}
