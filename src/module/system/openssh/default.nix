{ lib, config, ... }:

# TODO: authorized list of objects with host, user, key file

with lib;
let
  cfg = config.dot.openssh;
in
{
  options.dot.openssh = {
    enable = mkEnableOption "OpenSSH server";
    userName = mkOption {
      type = types.str;
      example = "haras";
      description = mdDoc ''
        OpsnSSH login user name.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.PermitRootLogin = "no";
    services.openssh.PasswordAuthentication = false;

    users.users."${cfg.userName}".openssh.authorizedKeys.keys = [
      ("${config.users.users."${cfg.userName}".homeDirectory}" + /.ssh/authorized.pub)
    ];
    sops.secrets."authorized.ssh.pub".path = "${config.users.users."${cfg.userName}".homeDirectory}" + /.ssh/authorized.pub;
    sops.secrets."authorized.ssh.pub".owner = "${cfg.userName}";
    sops.secrets."authorized.ssh.pub".group = "users";
    sops.secrets."authorized.ssh.pub".mode = "0600";
  };
}
