{
  lib,
  config,
  ...
}:

# TODO: only allow from nebula

let
  user = config.dot.host.user;
  hasNetwork = config.dot.hardware.network.enable;

  hosts = builtins.filter (x: x.system.services.openssh.enable or false) config.dot.host.hosts;
  otherHosts = builtins.filter (x: x.name != config.networking.hostName) hosts;
in
{
  nixosModule = lib.mkIf hasNetwork {
    services.openssh.enable = true;
    services.openssh.allowSFTP = true;
    services.openssh.settings.PermitRootLogin = "no";
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;
    services.openssh.authorizedKeysFiles = [
      ".ssh/authorized_keys"
      ".ssh/nebula_authorized_keys"
    ];

    # NOTE: otherwise sops leaves .ssh owner root
    systemd.tmpfiles.rules = [
      "d /home/${user}/.ssh 0700 ${user} ${user} - -"
    ];
    sops.secrets."ssh-private" = {
      path = "/home/${user}/.ssh/nebula_id_ed25519";
      owner = user;
      group = user;
      mode = "0600";
    };
    sops.secrets."ssh-public" = {
      path = "/home/${user}/.ssh/nebula_id_ed25519.pub";
      owner = user;
      group = user;
      mode = "0644";
    };
    sops.secrets."ssh-nebula-authorized-keys" = {
      path = "/home/${user}/.ssh/nebula_authorized_keys";
      owner = user;
      group = user;
      mode = "0644";
    };

    rumor.sops.keys = [
      "ssh-nebula-authorized-keys"
      "ssh-public"
      "ssh-private"
    ];
    rumor.specification.imports = builtins.map (host: {
      importer = "vault-file";
      arguments = {
        path = "kv/dot/shared";
        file = "${host.name}-ssh-public";
      };
    }) otherHosts;
    rumor.specification.generations = [
      {
        generator = "ssh-key";
        arguments = {
          name = config.networking.hostName;
          public = "ssh-public";
          private = "ssh-private";
        };
      }
      {
        generator = "moustache";
        arguments = {
          name = "ssh-nebula-authorized-keys";
          renew = true;
          variables = builtins.listToAttrs (
            builtins.map (host: {
              name = "${host.name}";
              value = "${host.name}-ssh-public";
            }) otherHosts
          );
          template = lib.concatMapStringsSep "\n" (host: "{{ ${host.name} }}") otherHosts;
        };
      }
    ];
    rumor.specification.exports = [
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

  homeManagerModule = {
    services.ssh-agent.enable = true;
    programs.ssh.enable = true;
    programs.ssh.enableDefaultConfig = false;

    programs.ssh.matchBlocks = lib.mkMerge [
      {
        # NOTE: moved from home-manager defaults
        "*" = {
          forwardAgent = false;
          addKeysToAgent = "yes";
          compression = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
        # NOTE: for easier interactive NixOS tests
        "vsock/*".extraOptions = {
          StrictHostKeyChecking = "no";
          UserKnownHostsFile = "/dev/null";
          GlobalKnownHostsFile = "/dev/null";
        };
      }
      (builtins.listToAttrs (
        builtins.map (host: {
          name = host.name;
          value = {
            hostname = host.ip;
            user = user;
            identityFile = "~/.ssh/nebula_id_ed25519";
          };
        }) otherHosts
      ))
    ];
  };
}
