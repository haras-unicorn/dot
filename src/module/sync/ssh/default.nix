{ lib, user, host, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
in
{
  system = lib.mkIf hasNetwork {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;

    sops.secrets."${host}.ssh" = {
      path = "/home/${user}/.ssh/id";
      owner = user;
      group = "users";
      mode = "0400";
    };

    sops.secrets."${host}.ssh.pub" = {
      path = "/home/${user}/.ssh/id.pub";
      owner = user;
      group = "users";
      mode = "0644";
    };

    sops.secrets."${host}.auth.pub" = {
      path = "/home/${user}/.ssh/authorized_keys";
      owner = user;
      group = "users";
      mode = "0644";
    };
  };
}
