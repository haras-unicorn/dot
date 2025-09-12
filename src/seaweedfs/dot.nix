{
  lib,
  config,
  pkgs,
  ...
}:

# TODO: security

let
  hasNetwork = config.dot.hardware.network.enable;

  user = config.dot.user;
  seaweedfsUser = "seaweedfs_${config.dot.host.name}";

  hosts = builtins.map (x: x.ip) (
    builtins.filter (
      x:
      if lib.hasAttrByPath [ "system" "dot" "fs" "coordinator" ] x then
        x.system.dot.fs.coordinator
      else
        false
    ) config.dot.hosts
  );

  peers = builtins.map (x: "${x}:${builtins.toString config.services.seaweedfs.master.httpPort}") (
    builtins.filter (x: x != config.dot.host.ip) hosts
  );

  masters = builtins.map (
    x: "${x}:${builtins.toString config.services.seaweedfs.master.httpPort}"
  ) hosts;

  filerPort = 8888;

  filers = builtins.concatStringsSep "," (
    builtins.map (x: "${x}:${builtins.toString filerPort}") hosts
  );

  seaweedfsUid = 18888;
  seaweedfsGid = 18888;
  userUid = config.users.users.${config.dot.user}.uid;
  userGid = config.users.groups.${config.dot.user}.gid;

  mountDir = "${config.users.users.${config.dot.user}.home}/weed";
  cacheDir = "${config.users.users.${config.dot.user}.home}/.weed-cache";
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.seaweedfs
      pkgs.postgresql
    ];
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      fs.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    config = lib.mkIf hasNetwork (
      lib.mkMerge [
        (lib.mkIf (!config.dot.fs.coordinator) {
          systemd.services.seaweedfs-mount = {
            description = "SeaweedFS FUSE mount";
            after = [ "vpn-online.target" ];
            requires = [ "vpn-online.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStartPre = [
                "${pkgs.coreutils}/bin/mkdir -p ${mountDir}"
                "${pkgs.coreutils}/bin/chown ${config.dot.user}:${config.dot.user} ${mountDir}"
              ];
              ExecStart = builtins.replaceStrings [ "\n" ] [ " " ] ''
                ${pkgs.seaweedfs}/bin/weed mount
                  -dir='${mountDir}'
                  -cacheDir='${cacheDir}'
                  -filer='${filers}'
                  -filer.path='${mountDir}'
                  -map.uid=${builtins.toString userUid}:${builtins.toString seaweedfsUid}
                  -map.gid=${builtins.toString userGid}:${builtins.toString seaweedfsGid}
              '';
            };
          };
        })
        (lib.mkIf config.dot.fs.coordinator {
          users.users.seaweedfs.uid = seaweedfsUid;
          users.groups.seaweedfs.gid = seaweedfsGid;

          services.seaweedfs.enable = true;

          services.seaweedfs.master.enable = true;
          services.seaweedfs.master.openFirewall = true;
          services.seaweedfs.master.ip = config.dot.host.ip;
          services.seaweedfs.master.peers = peers;
          systemd.services."seaweedfs-master".requires = [
            "vpn-online.target"
            "time-synced.target"
          ];
          systemd.services."seaweedfs-master".after = [
            "vpn-online.target"
            "time-synced.target"
          ];

          services.seaweedfs.volumes.dot.enable = true;
          # NOTE: 8080 is cockroachdb
          services.seaweedfs.volumes.dot.httpPort = 8081;
          services.seaweedfs.volumes.dot.ip = config.dot.host.ip;
          services.seaweedfs.volumes.dot.masterServers = masters;
          services.seaweedfs.volumes.dot.openFirewall = true;
          systemd.services."seaweedfs-volume@dot".requires = [ "seaweedfs-master.service" ];
          systemd.services."seaweedfs-volume@dot".after = [ "seaweedfs-master.service" ];

          services.seaweedfs.filers.dot.enable = true;
          services.seaweedfs.filers.dot.ip = config.dot.host.ip;
          services.seaweedfs.filers.dot.httpPort = filerPort;
          services.seaweedfs.filers.dot.masterServers = masters;
          services.seaweedfs.filers.dot.openFirewall = true;
          services.seaweedfs.filers.dot.environmentFile = config.sops.secrets."seaweedfs-filer-env".path;
          services.seaweedfs.filers.dot.config.postgres = {
            enabled = true;
            hostname = "localhost";
            port = config.services.cockroachdb.listen.port;
            username = seaweedfsUser;
            database = "seaweedfs";
          };
          systemd.services."seaweedfs-filer@dot".requires = [
            "seaweedfs-master.service"
            "cockroachdb-init.service"
          ];
          systemd.services."seaweedfs-filer@dot".after = [
            "seaweedfs-master.service"
            "cockroachdb-init.service"
          ];
          services.cockroachdb.initFiles = [ config.sops.secrets."cockroach-seaweedfs-init".path ];

          dot.consul.services = [
            {
              name = "seaweedfs-master";
              port = config.services.seaweedfs.master.httpPort;
              address = config.dot.host.ip;
              tags = [
                "dot.enable=true"
              ];
              check = {
                http = "http://${config.dot.host.ip}:${builtins.toString config.services.seaweedfs.master.httpPort}";
                interval = "30s";
                timeout = "10s";
              };
            }
            {
              name = "seaweedfs-volume";
              port = config.services.seaweedfs.volumes.dot.httpPort;
              address = config.dot.host.ip;
              tags = [
                "dot.enable=true"
              ];
              check = {
                http = "http://${config.dot.host.ip}:${builtins.toString config.services.seaweedfs.volumes.dot.httpPort}/status";
                interval = "30s";
                timeout = "10s";
              };
            }
            {
              name = "seaweedfs-filer";
              port = config.services.seaweedfs.filers.dot.httpPort;
              address = config.dot.host.ip;
              tags = [
                "dot.enable=true"
              ];
              check = {
                http = "http://${config.dot.host.ip}:${builtins.toString config.services.seaweedfs.filers.dot.httpPort}";
                interval = "30s";
                timeout = "10s";
              };
            }
          ];

          sops.secrets."seaweedfs-filer-env" = {
            owner = config.systemd.services."seaweedfs-filer@dot".serviceConfig.User;
            group = config.systemd.services."seaweedfs-filer@dot".serviceConfig.Group;
            mode = "0400";
          };
          sops.secrets."cockroach-seaweedfs-init" = {
            owner = config.systemd.services.cockroachdb.serviceConfig.User;
            group = config.systemd.services.cockroachdb.serviceConfig.User;
            mode = "0400";
          };
          rumor.sops = [
            "cockroach-seaweedfs-pass"
            "cockroach-seaweedfs-init"
            "seaweedfs-filer-env"
          ];
          rumor.specification.generations = [
            {
              generator = "key";
              arguments = {
                name = "cockroach-seaweedfs-pass";
              };
            }
            {
              generator = "moustache";
              arguments = {
                name = "cockroach-seaweedfs-init";
                renew = true;
                variables = {
                  COCKROACH_SEAWEEDFS_PASS = "cockroach-seaweedfs-pass";
                };
                template = ''
                  create user if not exists ${seaweedfsUser} password '{{COCKROACH_SEAWEEDFS_PASS}}';
                  create database if not exists seaweedfs;

                  \c seaweedfs
                  alter default privileges for all roles in schema public grant all on tables to ${seaweedfsUser};
                  alter default privileges for all roles in schema public grant all on sequences to ${seaweedfsUser};
                  alter default privileges for all roles in schema public grant all on functions to ${seaweedfsUser};

                  grant all on all tables in schema public to ${seaweedfsUser};
                  grant all on all sequences in schema public to ${seaweedfsUser};
                  grant all on all functions in schema public to ${seaweedfsUser};

                  alter default privileges for all roles in schema public grant all on tables to ${user};
                  alter default privileges for all roles in schema public grant all on sequences to ${user};
                  alter default privileges for all roles in schema public grant all on functions to ${user};

                  grant all on all tables in schema public to ${user};
                  grant all on all sequences in schema public to ${user};
                  grant all on all functions in schema public to ${user};

                  create table if not exists filemeta (
                    dirhash     bigint,
                    name        varchar(65535),
                    directory   varchar(65535),
                    meta        bytea,
                    primary key (dirhash, name)
                  );
                '';
              };
            }
            {
              generator = "env";
              arguments = {
                name = "seaweedfs-filer-env";
                renew = true;
                variables = {
                  WEED_POSTGRES_PASSWORD = "cockroach-seaweedfs-pass";
                };
              };
            }
          ];
        })
      ]
    );
  };
}
