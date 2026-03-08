{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-mounts =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.seaweedfs;
    in
    {
      options.services.seaweedfs = {
        mounts = lib.mkOption {
          default = { };
          description = "mount server instances";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, config, ... }:
              {
                imports = [ self.lib.seaweedfs.nixosSubmodules.client ];

                config = {
                  _module.args.pkgs = pkgs;
                  defaultStateDir = "/var/lib/seaweedfs/mounts/${name}";
                };

                options = {
                  mountDir = lib.mkOption {
                    type = lib.types.path;
                    default = "${config.stateDir}/bind";
                    description = "Directory to mount to";
                  };

                  mountUid = lib.mkOption {
                    type = lib.types.ints.u16;
                    default = config.users.users.seaweedfs.uid;
                    description = "User ID of the owner of the mount directory";
                  };

                  mountGid = lib.mkOption {
                    type = lib.types.ints.u16;
                    default = config.users.groups.seaweedfs.gid;
                    description = "Group ID of the owner of the mount directory";
                  };

                  filerPath = lib.mkOption {
                    type = lib.types.path;
                    default = "/";
                    description = "Path to mount from the filer servers";
                  };

                  filers = lib.mkOption {
                    type = lib.types.listOf (
                      lib.types.submodule {
                        options = {
                          server = lib.mkOption {
                            type = lib.types.str;
                            default = [ ];
                            description = "Filer server (host:httpPort)";
                          };

                          uid = lib.mkOption {
                            type = lib.types.ints.u16;
                            description = "User ID of the user running the filer server";
                          };

                          gid = lib.mkOption {
                            type = lib.types.ints.u16;
                            description = "Group ID of the user running the filer server";
                          };
                        };
                      }
                    );
                    default = [ ];
                    description = "filer servers to connect to";
                  };
                };
              }
            )
          );
        };
      };

      config = {
        services.seaweedfs.clients = lib.mapAttrs' (name: mountCfg: {
          name = "mount@${name}";
          value = {
            clientConfig = mountCfg;
            serviceConfig = {
              ExecStartPre = [
                "${pkgs.coreutils}/bin/mkdir -p ${mountCfg.stateDir}/mount"

                "${pkgs.coreutils}/bin/mkdir -p ${mountCfg.mountDir}"
                (
                  "${pkgs.coreutils}/bin/chown"
                  + " ${builtins.toString mountCfg.mountUid}:${builtins.toString mountCfg.mountGid}"
                  + " ${mountCfg.mountDir}"
                )

                "${pkgs.util-linux}/bin/umount ${mountCfg.stateDir}/mount"
              ];
              ExecStopPost = [
                "${pkgs.util-linux}/bin/umount ${mountCfg.stateDir}/mount"
              ];
              CapabilityBoundingSet = [
                "CAP_SYS_ADMIN"
                "CAP_SETUID"
                "CAP_SETGID"
              ];
              AmbientCapabilities = [
                "CAP_SYS_ADMIN"
                "CAP_SETUID"
                "CAP_SETGID"
              ];
            };
            command = "mount";
            args = [
              "-dir='${mountCfg.stateDir}/mount'"
              "-cacheDir='${mountCfg.stateDir}/cache'"
              "-filer='${builtins.concatStringsSep "," (builtins.map (filer: filer.server) mountCfg.filers)}'"
              "-filer.path='${mountCfg.filerPath}'"
            ]
            ++ lib.flatten (
              builtins.map (filer: [
                "-map.uid=${builtins.toString mountCfg.mountUid}:${builtins.toString filer.uid}"
                "-map.gid=${builtins.toString mountCfg.mountGid}:${builtins.toString filer.gid}"
              ]) mountCfg.filers
            );
          };
        }) cfg.mounts;

        systemd.mounts = builtins.map (
          { name, value }:
          {
            what = "${value.stateDir}/mount";
            where = value.mountDir;
            type = "none";
            options = "bind";
            wantedBy = [ "multi-user.target" ];
            requires = [ "seaweedfs-mount@${name}.service" ];
            after = [ "seaweedfs-mount@${name}.service" ];
          }
        ) (lib.attrsToList (lib.filterAttrs (_: { enable, ... }: enable) cfg.mounts));
      };
    };
}
