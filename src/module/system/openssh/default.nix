{ lib, config, ... }:

# TODO: authorized list of objects with host, user, key file

with lib;
let
  cfg = config.dot.openssh;
in
{
  options.dot.openssh = {
    enable = mkEnableOption "OpenSSH server";
    authorizations = mkOption {
      type = with types; lazyAttrsOf (listOf str);
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
      services.openssh.settings.PasswordAuthentication = false;
      services.openssh.settings.KbdInteractiveAuthentication = false;
    }
    // (builtins.foldl'
      (result: user: result
        // (builtins.map
        (host: {
          sops.secrets."${user}-${host}.ssh.pub".path = "${config.users.users."${user}".home}" + /.ssh/${host}.authorized.ssh.pub;
          sops.secrets."${user}-${host}.ssh.pub".owner = "${user}";
          sops.secrets."${user}-${host}.ssh.pub".group = "users";
          sops.secrets."${user}-${host}.ssh.pub".mode = "0600";
        })
        (cfg.authorizations."${user}"))
        // ({
        system.activationScripts."openssh-${user}-authorized-keys" = {
          text = ''
            cat /home/${user}/.ssh/*.authorized.ssh.pub > /home/${user}/.ssh/authorized_keys
            chown ${user}:users /home/${user}/.ssh/authorized_keys
            chmod 600 /home/${user}/.ssh/authorized_keys
          '';
          deps = [ ];
        };
      })
      )
      ({ })
      (builtins.attrNames cfg.authorizations))
    );
}
