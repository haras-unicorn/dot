{ lib, user, host, config, ... }:

# TODO: only allow from vpn

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  system = lib.mkIf hasNetwork {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;
    sops.secrets."${host}.ssh.auth.pub" = {
      path = "/home/${user}/.ssh/authorized_keys";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."${host}.ssh.key.pub" = {
      path = "/home/${user}/.ssh/id.pub";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."${host}.ssh.key" = {
      path = "/home/${user}/.ssh/id";
      owner = user;
      group = "users";
      mode = "0400";
    };
  };
}
