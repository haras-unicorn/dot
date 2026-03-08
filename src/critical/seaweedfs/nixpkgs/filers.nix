{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-filers =
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
        filers = lib.mkOption {
          default = { };
          description = "Filer server instances";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                imports = [ self.lib.seaweedfs.nixosSubmodules.server ];

                config = {
                  _module.args.pkgs = pkgs;
                  defaultStateDir = "/var/lib/seaweedfs/filers/${name}";
                  defaultHttpPort = 8888;
                  defaultGrpcPort = 18888;
                };

                options = {
                  dataCenter = lib.mkOption {
                    type = lib.types.str;
                    description = "Filer server data center location";
                  };

                  rack = lib.mkOption {
                    type = lib.types.str;
                    description = "Filer server rack location";
                  };

                  masterServers = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [ ];
                    description = "List of master servers (host:(httpPort(.grpcPort)?)?)";
                  };

                  config = lib.mkOption {
                    type = lib.types.anything;
                    default = { };
                    description = "Contents of filer.toml for the filer server";
                  };
                };
              }
            )
          );
        };
      };

      config = {
        services.seaweedfs.servers = lib.mapAttrs' (
          name: filerCfg:
          let
            configFile = pkgs.writers.writeTOML "filer.toml" filerCfg.config;
          in
          {
            name = "filer@${name}";
            value = {
              serverConfig = filerCfg;
              serviceConfig = {
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/ln -sf ${configFile} ${filerCfg.stateDir}/filer.toml"
                ];
              };
              command = "filer";
              args = [
                "-dataCenter=${filerCfg.dataCenter}"
                "-rack=${filerCfg.rack}"
                "-master=${lib.concatStringsSep "," filerCfg.masterServers}"
              ];
            };
          }
        ) cfg.filers;
      };
    };
}
