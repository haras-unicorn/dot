{ self, ... }:

# TODO: only allow from network

{
  dot.cli = {
    makeRuntimeInputs = [ (pkgs: [ pkgs.openssh ]) ];
    text = builtins.readFile ./cli.nu;
  };

  flake.nixosModules.critical-openssh =
    { lib, config, ... }:
    let
      user = config.dot.host.user;
      hostname = config.dot.host.name;
      hasNetwork = config.dot.hardware.network.enable;
      hosts = config.dot.host.hosts;
    in
    {
      config = lib.mkIf hasNetwork {
        services.openssh.enable = true;
        services.openssh.allowSFTP = true;
        services.openssh.settings.PermitRootLogin = "no";
        services.openssh.settings.PasswordAuthentication = false;
        services.openssh.settings.KbdInteractiveAuthentication = false;
        services.openssh.settings.AddressFamily = "inet";
        services.openssh.settings.HostKey = "/etc/ssh/ssh_host_dot";
        # NOTE: a bit hacky but the "official" options are too static
        services.openssh.authorizedKeysFiles = [ "%h/.ssh/dot_authorized_keys" ];

        # NOTE: a bit hacky but the "official" options are too static
        programs.ssh.extraConfig = ''
          AddressFamily inet
          UserKnownHostsFile %d/.ssh/known_hosts %d/.ssh/known_hosts2 %d/.ssh/dot_known_hosts
        '';

        # NOTE: otherwise sops leaves .ssh owner root
        systemd.tmpfiles.rules = [
          "d ${config.dot.host.home}/.ssh 0700 ${user} ${user} - -"
        ];
        # NOTE: a bit hacky but the "official" options are too static
        sops.secrets."ssh-authorized-keys" = {
          path = "${config.dot.host.home}/.ssh/dot_authorized_keys";
          owner = user;
          group = user;
          mode = "0644";
        };
        # NOTE: a bit hacky but the "official" options are too static
        sops.secrets."ssh-known-hosts" = {
          path = "${config.dot.host.home}/.ssh/dot_known_hosts";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."ssh-public" = {
          path = "${config.dot.host.home}/.ssh/dot.pub";
          owner = user;
          group = user;
          mode = "0644";
        };
        sops.secrets."ssh-private" = {
          path = "${config.dot.host.home}/.ssh/dot";
          owner = user;
          group = user;
          mode = "0600";
        };
        sops.secrets."ssh-server-public" = {
          path = "/etc/ssh/ssh_host_dot.pub";
          owner = "root";
          group = "root";
          mode = "0644";
        };
        sops.secrets."ssh-server-private" = {
          path = "/etc/ssh/ssh_host_dot";
          owner = "root";
          group = "root";
          mode = "0600";
        };

        cryl.sops.keys = [
          "ssh-authorized-keys"
          "ssh-known-hosts"
          "ssh-server-public"
          "ssh-server-private"
          "ssh-public"
          "ssh-private"
        ];
        cryl.specification.imports = lib.flatten (
          builtins.map (host: [
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-public";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-private";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-server-public";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-server-private";
                allow_fail = true;
              };
            }
          ]) hosts
        );
        cryl.specification.generations =
          (lib.flatten (
            builtins.map (host: [
              {
                generator = "ssh-key";
                arguments = {
                  name = host.name;
                  public = "${host.name}-ssh-public";
                  private = "${host.name}-ssh-private";
                };
              }
              {
                generator = "ssh-key";
                arguments = {
                  name = host.name;
                  public = "${host.name}-ssh-server-public";
                  private = "${host.name}-ssh-server-private";
                };
              }
            ]) hosts
          ))
          ++ [
            {
              generator = "copy";
              arguments = {
                from = "${hostname}-ssh-public";
                to = "ssh-public";
                renew = true;
              };
            }
            {
              generator = "copy";
              arguments = {
                from = "${hostname}-ssh-private";
                to = "ssh-private";
                renew = true;
              };
            }
            {
              generator = "copy";
              arguments = {
                from = "${hostname}-ssh-server-public";
                to = "ssh-server-public";
                renew = true;
              };
            }
            {
              generator = "copy";
              arguments = {
                from = "${hostname}-ssh-server-private";
                to = "ssh-server-private";
                renew = true;
              };
            }
            {
              generator = "moustache";
              arguments = {
                name = "ssh-authorized-keys";
                variables = builtins.listToAttrs (
                  builtins.map (host: {
                    name = "${lib.toUpper host.name}_SSH_PUBLIC";
                    value = "${host.name}-ssh-public";
                  }) hosts
                );
                template = builtins.concatStringsSep "\n" (
                  builtins.map (host: "{{${lib.toUpper host.name}_SSH_PUBLIC}}") hosts
                );
                renew = true;
              };
            }
            {
              generator = "moustache";
              arguments = {
                name = "ssh-known-hosts";
                variables = builtins.listToAttrs (
                  builtins.map (host: {
                    name = "${lib.toUpper host.name}_SSH_SERVER_PUBLIC";
                    value = "${host.name}-ssh-server-public";
                  }) hosts
                );
                template = builtins.concatStringsSep "\n" (
                  lib.flatten (
                    builtins.map (host: [
                      "${host.ip} {{${lib.toUpper host.name}_SSH_SERVER_PUBLIC}}"
                    ]) hosts
                  )
                );
                renew = true;
              };
            }
          ];
        cryl.specification.exports = lib.flatten (
          builtins.map (host: [
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-public";
              };
            }
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-private";
              };
            }
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-server-public";
              };
            }
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "${host.name}-ssh-server-private";
              };
            }
          ]) hosts
        );
      };
    };
}
