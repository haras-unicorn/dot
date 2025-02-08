{ pkgs, host, config, user, group, uid, gid, lib, ... }:

# FIXME: /var/lib/ mount creates dependency cycle

let
  rootDomain = "s3.garage";

  hasNetwork = config.dot.hardware.network.enable;

  ip = config.dot.vpn.ip;
  rpcPort = 3900;
  adminPort = rpcPort + 1;
  webPort = rpcPort + 2;
  apiPort = rpcPort + 3;

  isCoordinator = config.dot.nfs.coordinator;
  isTrusted = config.dot.nfs.trusted;
  bindAddr = if isCoordinator then ip else "127.0.0.1";

  mkRcloneOptions = uid: gid: conf: builtins.concatStringsSep "," [
    "config=${conf}"
    "vfs-cache-mode=writes"
    "gid=${builtins.toString gid}"
    "uid=${builtins.toString uid}"
    "dir-perms=700"
    "file-perms=600"
  ];
  # mkRootRcloneOption = uid: gid: mkRcloneOptions uid gid "/etc/rclone/rclone.conf";
  userRcloneOptions = mkRcloneOptions uid gid "${config.home.homeDirectory}/.rclone.conf";

  pathToMountName = path:
    (lib.replaceStrings
      [ "/" ]
      [ "-" ]
      (lib.strings.removePrefix "/" path));
in
{
  disabled = true;

  options = {
    nfs.coordinator = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    nfs.node = lib.mkOption {
      type = lib.types.strMatching "[a-z0-9]+";
      default = false;
    };
    nfs.trusted = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  system = lib.mkIf hasNetwork {
    services.garage.enable = true;
    services.garage.package = pkgs.garage;
    services.garage.environmentFile = "/etc/garage/host.env";
    systemd.services.garage.after = [ "nebula@nebula.service" ];
    systemd.services.garage.wants = [ "nebula@nebula.service" ];
    sops.secrets."shared.nfs.env" = {
      path = "/etc/garage/host.env";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    networking.firewall.allowedUDPPorts = [ rpcPort ];
    networking.firewall.allowedTCPPorts = lib.mkMerge [
      [ rpcPort ]
      (lib.mkIf isCoordinator [ adminPort webPort apiPort ])
    ];
    services.garage.settings = {
      replication_factor = 2;
      db_engine = "sqlite";
      metadata_fsync = true;
      data_fsync = true;
      rpc_bind_addr = "${ip}:${builtins.toString rpcPort}";
      rpc_bind_outgoing = true;
      rpc_public_addr = "${ip}:${builtins.toString rpcPort}";
      bootstrap_peers = builtins.map
        (name:
          let
            other = config.dot.static.${name};
          in
          "${other.nfs.node}@${other.vpn.ip}:${builtins.toString rpcPort}")
        (builtins.filter
          (other: other != host)
          (builtins.attrNames config.dot.static));
      admin = {
        api_bind_addr = "${bindAddr}:${builtins.toString adminPort}";
      };
      s3_web = {
        bind_addr = "${bindAddr}:${builtins.toString webPort}";
        root_domain = rootDomain;
      };
      s3_api = {
        api_bind_addr = "${bindAddr}:${builtins.toString apiPort}";
        s3_region = "garage";
        root_domain = rootDomain;
      };
    };

    environment.systemPackages = [
      pkgs.rclone
    ];
    # systemd.mounts = [
    #   {
    #     description = "Mount garage:vaultwarden-attachments to /var/lib/vaultwarden/attachments";
    #     after = [ "garage.service" ];
    #     wants = [ "garage.service" ];
    #     wantedBy = [ "default.target" ];
    #     what = "garage:vaultwarden-attachments";
    #     where = "/var/lib/vaultwarden/attachments";
    #     type = "rclone";
    #     options = mkRootRcloneOption
    #       config.users.users.vaultwarden.uid
    #       config.users.groups.vaultwarden.gid;
    #   }
    # ];
    sops.secrets."system-rclone-conf" = {
      key = "${host}.nfs.cnf";
      path = "/etc/rclone/rclone.conf";
      owner = "root";
      group = "root";
      mode = "0400";
    };
    sops.secrets."home-rclone-conf" = {
      key = "${host}.nfs.cnf";
      path = "${config.users.users.${user}.home}/.rclone.conf";
      owner = user;
      group = group;
      mode = "0400";
    };
  };

  home = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.rclone
    ];
    systemd.user.mounts = {
      ${pathToMountName config.xdg.userDirs.documents} = lib.mkIf isTrusted {
        Unit = {
          Description = "Mount garage:documents as user documents directory";
          After = [ "garage.service" ];
          Wants = [ "garage.service" ];
        };
        Mount = {
          What = "garage:documents";
          Where = config.xdg.userDirs.documents;
          Type = "rclone";
          Options = userRcloneOptions;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      ${pathToMountName config.xdg.userDirs.music} = {
        Unit = {
          Description = "Mount garage:music as user music directory";
          After = [ "garage.service" ];
          Wants = [ "garage.service" ];
        };
        Mount = {
          What = "garage:music";
          Where = config.xdg.userDirs.music;
          Type = "rclone";
          Options = userRcloneOptions;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      ${pathToMountName config.xdg.userDirs.pictures} = lib.mkIf isTrusted {
        Unit = {
          Description = "Mount garage:pictures as user pictures directory";
          After = [ "garage.service" ];
          Wants = [ "garage.service" ];
        };
        Mount = {
          What = "garage:pictures";
          Where = config.xdg.userDirs.pictures;
          Type = "rclone";
          Options = userRcloneOptions;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      ${pathToMountName config.xdg.userDirs.videos} = lib.mkIf isTrusted {
        Unit = {
          Description = "Mount garage:videos as user videos directory";
          After = [ "garage.service" ];
          Wants = [ "garage.service" ];
        };
        Mount = {
          What = "garage:videos";
          Where = config.xdg.userDirs.videos;
          Type = "rclone";
          Options = userRcloneOptions;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      ${pathToMountName config.xdg.userDirs.publicShare} = {
        Unit = {
          Description = "Mount garage:data as user public share directory";
          After = [ "garage.service" ];
          Wants = [ "garage.service" ];
        };
        Mount = {
          What = "garage:data";
          Where = config.xdg.userDirs.publicShare;
          Type = "rclone";
          Options = userRcloneOptions;
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
