{ lib, config, ... }:

# TODO: only allow from vpn

let
  user = config.dot.user;
  host = config.dot.host;

  hasNetwork = config.dot.hardware.network.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;
    sops.secrets."${host.name}.ssh.auth.pub" = {
      path = "/home/${user}/.ssh/authorized_keys";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."${host.name}.ssh.key.pub" = {
      path = "/home/${user}/.ssh/id.pub";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."${host.name}.ssh.key" = {
      path = "/home/${user}/.ssh/id";
      owner = user;
      group = "users";
      mode = "0400";
    };
  };

  branch.homeManagerModule.homeManagerModule = {
    programs.ssh.enable = true;
    services.ssh-agent.enable = true;
  };
}
