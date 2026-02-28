{ ... }:

# TODO: only allow from nebula

{
  flake.nixosModules.critical-openssh =
    { lib, config, ... }:
    let
      user = config.dot.host.user;
      hasNetwork = config.dot.hardware.network.enable;
    in
    {
      config = lib.mkIf hasNetwork {
        services.openssh.enable = true;
        services.openssh.allowSFTP = true;
        services.openssh.settings.PermitRootLogin = "no";
        services.openssh.settings.PasswordAuthentication = false;
        services.openssh.settings.KbdInteractiveAuthentication = false;

        # NOTE: otherwise sops leaves .ssh owner root
        systemd.tmpfiles.rules = [
          "d /home/${user}/.ssh 0700 ${user} ${user} - -"
        ];
        sops.secrets."ssh-public" = {
          path = "/home/${user}/.ssh/authorized_keys";
          owner = user;
          group = user;
          mode = "0644";
        };

        rumor.sops.keys = [
          "ssh-authorized-keys"
          "ssh-public"
          "ssh-private"
        ];
        rumor.specification.generations = [
          {
            generator = "ssh-keygen";
            arguments = {
              name = config.networking.hostName;
              public = "ssh-public";
              private = "ssh-private";
            };
          }
        ];
        rumor.specification.exports = [
          # TODO: generate with moustache from other hosts
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
    };
}
