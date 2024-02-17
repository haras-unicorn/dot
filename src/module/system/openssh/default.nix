{ lib, config, ... }:

# FIXME: fix the ssh key thing

with lib;
let
  cfg = config.dot.openssh;
in
{
  options.dot.openssh = {
    enable = mkEnableOption "OpenSSH server";
    authorizations = mkOption {
      type = with types; attrsOf (listOf str);
      default = { };
      example = {
        user1 = [ "host1" ];
      };
      description = mdDoc ''
        OpenSSH authorized keys specification
      '';
    };
  };

  config = mkIf cfg.enable
    ({
      services.openssh.enable = true;
      services.openssh.allowSFTP = true;
      services.openssh.settings.PermitRootLogin = "no";
      services.openssh.settings.PasswordAuthentication = true;
      services.openssh.settings.KbdInteractiveAuthentication = false;
    }
      # // (attrsets.concatMapAttrs
      #   (user: hosts:
      #     (lists.foldl'
      #       (result: host: result
      #         // ({
      #         sops.secrets."${user}-${host}.ssh.pub".path = "${config.users.users."${user}".home}" + /.ssh/${host}.authorized.ssh.pub;
      #         sops.secrets."${user}-${host}.ssh.pub".owner = "${user}";
      #         sops.secrets."${user}-${host}.ssh.pub".group = "users";
      #         sops.secrets."${user}-${host}.ssh.pub".mode = "0600";
      #       })
      #       )
      #       ({ })
      #       (hosts))
      #     // ({
      #       system.activationScripts."openssh-${user}-authorized-keys" = {
      #         text = ''
      #           cat /home/${user}/.ssh/*.authorized.ssh.pub > /home/${user}/.ssh/authorized_keys
      #           chown ${user}:users /home/${user}/.ssh/authorized_keys
      #           chmod 600 /home/${user}/.ssh/authorized_keys
      #         '';
      #         deps = [ ];
      #       };
      #     })
      #   )
      #   (cfg.authorizations))
    );
}
