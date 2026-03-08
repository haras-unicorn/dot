{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-volumes =
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
        volumes = lib.mkOption {
          default = { };
          description = "Volume server instances";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { config, name, ... }:
              {
                imports = [ self.lib.seaweedfs.nixosSubmodules.server ];

                config = {
                  _module.args.pkgs = pkgs;
                  defaultStateDir = "/var/lib/seaweedfs/volumes/${name}";
                  defaultHttpPort = 8080;
                  defaultGrpcPort = 18080;
                };

                options = {
                  dataDir = lib.mkOption {
                    type = lib.types.path;
                    default = "${config.stateDir}/data";
                    description = "Volume data directory";
                  };

                  max = lib.mkOption {
                    type = lib.types.str;
                    default = "0";
                    description = "Volume maximum capacity. 0 indicates no limit.";
                  };

                  dataCenter = lib.mkOption {
                    type = lib.types.str;
                    description = "Volume server data center location";
                  };

                  rack = lib.mkOption {
                    type = lib.types.str;
                    description = "Volume server rack location";
                  };

                  masterServers = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "List of master servers (host:(httpPort(.grpcPort)?)?)";
                  };
                };
              }
            )
          );
        };
      };

      config = {
        services.seaweedfs.servers = (
          lib.mapAttrs' (name: volumeCfg: {
            name = "volume@${name}";
            value = {
              serverConfig = volumeCfg;
              serviceConfig = {
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/mkdir -p '${volumeCfg.dataDir}'"
                ];
              };
              command = "volume";
              args = [
                "-dataCenter=${volumeCfg.dataCenter}"
                "-rack=${volumeCfg.rack}"
                "-max=${volumeCfg.max}"
                "-mserver=${lib.concatStringsSep "," volumeCfg.masterServers}"
                "-dir=${volumeCfg.dataDir}"
              ];
            };
          }) cfg.volumes
        );
      };
    };
}
