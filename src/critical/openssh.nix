{ self, ... }:

# TODO: only allow from network

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
        services.openssh.settings.PermitRootLogin = lib.mkForce "no";
        services.openssh.settings.PasswordAuthentication = lib.mkForce false;
        services.openssh.settings.KbdInteractiveAuthentication = lib.mkForce false;

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
            generator = "ssh-key";
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
              path = self.lib.rumor.shared;
              file = "${config.networking.hostName}-ssh-public";
            };
          }
        ];
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openssh = self.lib.test.mkTest pkgs {
        name = "critical-openssh";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-openssh
          ];
        };
        testScript = ''
          start_all()
          machine.succeed("systemctl is-enabled sshd.service")
          machine.succeed("grep 'PermitRootLogin no' /etc/ssh/sshd_config")
          machine.succeed("grep 'PasswordAuthentication no' /etc/ssh/sshd_config")
          machine.succeed("grep 'KbdInteractiveAuthentication no' /etc/ssh/sshd_config")
        '';
      };
    };
}
