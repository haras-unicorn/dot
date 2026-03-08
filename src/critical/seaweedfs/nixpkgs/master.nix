{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-master =
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
        master = lib.mkOption {
          default = { };
          type = lib.types.submodule (
            { config, ... }:
            {
              imports = [ self.lib.seaweedfs.nixosSubmodules.server ];

              config = {
                _module.args.pkgs = pkgs;
                defaultStateDir = "/var/lib/seaweedfs/master";
                defaultHttpPort = 9333;
                defaultGrpcPort = 19333;
              };

              options = {
                dataDir = lib.mkOption {
                  type = lib.types.path;
                  default = "${config.stateDir}/data";
                  description = "Master data directory";
                };

                volumeSizeLimitMB = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  default = 30000;
                  description = "Volume size limit in MB";
                };

                peers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "List of master peers (host:(httpPort(.grpcPort)?)?)";
                  example = [
                    "192.168.1.10"
                    "192.168.1.11:9333"
                    "192.168.1.11:9333.19333"
                  ];
                };
              };
            }
          );
        };
      };

      config = {
        services.seaweedfs.servers.master = {
          serverConfig = cfg.master;
          command = "master";
          serviceConfig = {
            ExecStartPre = [
              "${pkgs.coreutils}/bin/mkdir -p '${cfg.master.dataDir}'"
            ];
          };
          args = [
            "-mdir=${cfg.master.dataDir}"
            "-peers=${lib.concatStringsSep "," cfg.master.peers}"
            "-volumeSizeLimitMB=${builtins.toString cfg.master.volumeSizeLimitMB}"
          ];
        };
      };
    };
}
