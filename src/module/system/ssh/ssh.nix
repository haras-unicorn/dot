{ ... }:

{
  programs.ssh.startAgent = true;
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  security.pam.enableSSHAgentAuth = true;
}
