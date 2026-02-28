{ config, ... }:

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

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openssh = config.flake.lib.test.mkTest pkgs {
        name = "critical-openssh";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-openssh
            config.flake.nixosModules.rumor
          ];
          options.dot.hardware.network.enable = pkgs.lib.mkOption {
            type = pkgs.lib.types.bool;
            default = true;
          };
          options.dot.host.user = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "testuser";
          };
          options.sops.secrets = pkgs.lib.mkOption {
            type = pkgs.lib.types.attrsOf pkgs.lib.types.raw;
            default = { };
          };
          config = {
            networking.hostName = "testhost";
            users.users.testuser = {
              isNormalUser = true;
              home = "/home/testuser";
            };
          };
        };
        script = ''
          start_all()
          machine.succeed("systemctl is-enabled sshd.service")
          machine.succeed("grep 'PermitRootLogin no' /etc/ssh/sshd_config")
          machine.succeed("grep 'PasswordAuthentication no' /etc/ssh/sshd_config")
          machine.succeed("grep 'KbdInteractiveAuthentication no' /etc/ssh/sshd_config")
        '';
      };
    };
}
