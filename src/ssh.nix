{ lib, config, ... }:

# TODO: only allow from vpn

let
  user = config.dot.user;
  hasNetwork = config.dot.hardware.network.enable;
in
{
  branch.nixosModule.nixosModule = lib.mkIf hasNetwork {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;

    sops.secrets."ssh-authorized-keys" = {
      path = "/home/${user}/.ssh/authorized_keys";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."ssh-public" = {
      path = "/home/${user}/.ssh/id_rsa.pub";
      owner = user;
      group = "users";
      mode = "0644";
    };
    sops.secrets."ssh-private" = {
      path = "/home/${user}/.ssh/id_rsa";
      owner = user;
      group = "users";
      mode = "0400";
    };

    rumor.sops = [
      "ssh-authorized-keys"
      "ssh-public"
      "ssh-private"
    ];
    rumor.generations = [
      {
        generator = "ssh-keygen";
        arguments = {
          name = config.networking.hostName;
          public = "ssh-public";
          private = "ssh-private";
        };
      }
    ];
    rumor.exports = [
      # TODO: generate with moustache from other hosts
      {
        exporter = "copy";
        arguments = {
          from = "ssh-public";
          to = "ssh-authorized-keys";
        };
      }
      {
        exporter = "copy";
        arguments = {
          from = "ssh-public";
          to = "${config.networking.hostName}-ssh-public";
        };
      }
      {
        exporter = "vault-file";
        arguments = {
          path = "kv/dot/shared";
          file = "${config.networking.hostName}-ssh-public";
        };
      }
    ];
  };

  branch.homeManagerModule.homeManagerModule = {
    programs.ssh.enable = true;
    services.ssh-agent.enable = true;
  };
}
