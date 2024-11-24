{ pkgs, host, config, uid, gid, lib, ... }:

let
  rootDomain = "s3.garage";

  hasNetwork = config.dot.hardware.network.enable;

  ip = config.dot.vpn.ip;
  rpcPort = 3900;
  adminPort = rpcPort + 1;
  webPort = rpcPort + 2;
  apiPort = rpcPort + 3;

  isCoordinator = config.dot.nfs.coordinator;
  bindAddr = if isCoordinator then ip else "127.0.0.1";

  mkRcloneOptions = uid: gid: builtins.concatStringsSep "," [
    "config=/etc/rclone/rclone.conf"
    "vfs-cache-mode=writes"
    "gid=${gid}"
    "uid=${uid}"
    "dir-perms=700"
    "file-perms=600"
  ];
  userRcloneOptions = mkRcloneOptions uid gid;
in
{
  options = {
    nfs.coordinator = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    nfs.node = lib.mkOption {
      type = lib.types.strMatching "[a-z0-9]+";
      default = false;
    };
  };

  config = {
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
      sops.secrets."${host}.nfs.cnf" = {
        path = "/etc/rclone/rclone.conf";
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };

    home = lib.mkIf hasNetwork {
      home.packages = [
        pkgs.rclone
      ];

      systemd.user.mounts = [
        {
          what = "garage:documents";
          where = config.xdg.userDirs.documents;
          type = "rclone";
          options = userRcloneOptions;
          wantedBy = [ "multi-user.target" ];
        }
        {
          what = "garage:music";
          where = config.xdg.userDirs.music;
          type = "rclone";
          options = userRcloneOptions;
          wantedBy = [ "multi-user.target" ];
        }
        {
          what = "garage:pictures";
          where = config.xdg.userDirs.pictures;
          type = "rclone";
          options = userRcloneOptions;
          wantedBy = [ "multi-user.target" ];
        }
        {
          what = "garage:videos";
          where = config.xdg.userDirs.videos;
          type = "rclone";
          options = userRcloneOptions;
          wantedBy = [ "multi-user.target" ];
        }
        {
          what = "garage:data";
          where = config.xdg.userDirs.publicShare;
          type = "rclone";
          options = userRcloneOptions;
          wantedBy = [ "multi-user.target" ];
        }
      ];
    };
  };
}
