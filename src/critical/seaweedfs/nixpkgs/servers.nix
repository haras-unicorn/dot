{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-servers =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      servers = lib.filterAttrs (_: config: config.serverConfig.enable) config.services.seaweedfs.servers;
    in
    {
      options.services.seaweedfs = {
        servers = lib.mkOption {
          description = ''SeaweedFS servers'';
          internal = true;
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                serverConfig = lib.mkOption {
                  type = lib.types.submodule {
                    imports = [ self.lib.seaweedfs.nixosSubmodules.server ];
                    freeformType = lib.types.attrsOf lib.types.raw;
                    _module.args.pkgs = pkgs;
                  };
                  description = ''SeaweedFS server configuration'';
                };

                serviceConfig = lib.mkOption {
                  # NOTE: fucking nixos...
                  type = lib.types.attrsOf utils.systemdUtils.unitOptions.unitOption;
                  default = { };
                  description = ''Extra server service config'';
                };

                command = lib.mkOption {
                  type = lib.types.str;
                  description = "SeaweedFS server command";
                };

                args = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = ''SeaweedFS server arguments'';
                };
              };
            }
          );
        };
      };

      config = {
        users.users = lib.mapAttrs' (name: config: {
          name = config.serverConfig.user;
          value = {
            isSystemUser = true;
            group = config.serverConfig.group;
            description = "SeaweedFS ${name} system user";
          };
        }) servers;

        users.groups = lib.mapAttrs' (name: config: {
          name = config.serverConfig.user;
          value = { };
        }) servers;

        networking.firewall.allowedTCPPorts = lib.flatten (
          builtins.map (
            server:
            if server.serverConfig.openFirewall then
              [
                server.serverConfig.httpPort
                server.serverConfig.grpcPort
              ]
            else
              [ ]
          ) (builtins.attrValues servers)
        );

        systemd.services = lib.mapAttrs' (
          name:
          {
            serverConfig,
            serviceConfig,
            command,
            args,
          }:
          let
            securityFile = pkgs.writers.writeTOML "security.toml" serverConfig.security;
          in
          {
            name = "seaweedfs-${name}";
            value = {
              description = "SeaweedFS ${name}";
              wantedBy = [ "multi-user.target" ];
              after = [ "network.target" ];

              serviceConfig = lib.mkMerge [
                serviceConfig
                {
                  WorkingDirectory = serverConfig.stateDir;
                  StateDirectory = lib.removePrefix "/var/lib/" serverConfig.stateDir;
                  StateDirectoryMode = "0700";
                  Restart = "always";
                  User = serverConfig.user;
                  Group = serverConfig.group;
                  Environment = lib.mapAttrsToList (name: value: "${name}=${value}") serverConfig.environment;
                  EnvironmentFile = lib.mkIf (serverConfig.environmentFile != null) serverConfig.environmentFile;
                  ExecStartPre = [
                    "${pkgs.coreutils}/bin/ln -sf ${securityFile} ${serverConfig.stateDir}/security.toml"
                  ];
                  ExecStart =
                    let
                      finalArgs = lib.concatStringsSep " " (
                        [
                          "-ip=${serverConfig.ip}"
                          "-port=${builtins.toString serverConfig.httpPort}"
                          "-port.grpc=${builtins.toString serverConfig.grpcPort}"
                        ]
                        ++ args
                        ++ serverConfig.extraArgs
                      );
                    in
                    "${lib.getExe serverConfig.package} ${command} ${finalArgs}";
                }
              ];
            };
          }
        ) servers;
      };
    };

  libAttrs.seaweedfs.nixosSubmodules.server =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options = {
        enable = lib.mkEnableOption "this SeaweedFS server";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.seaweedfs;
          description = "SeaweedFS package to use.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "seaweedfs";
          description = "User to run the service as";
        };

        group = lib.mkOption {
          type = lib.types.str;
          default = "seaweedfs";
          description = "Group to run the service as";
        };

        openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to open firewall for this server";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Environment variables";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Environment file containing secrets";
        };

        security = lib.mkOption {
          type = lib.types.anything;
          default = { };
          description = "Contents of security.toml for server";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command line arguments";
        };

        stateDir = lib.mkOption {
          type = lib.types.path;
          default = config.defaultStateDir;
          description = "Server state directory";
        };

        ip = lib.mkOption {
          type = lib.types.str;
          description = "Server IP";
        };

        httpPort = lib.mkOption {
          type = lib.types.port;
          default = config.defaultHttpPort;
          description = "Server HTTP port";
        };

        grpcPort = lib.mkOption {
          type = lib.types.port;
          default = config.defaultGrpcPort;
          description = "Server gRPC port";
        };

        defaultStateDir = lib.mkOption {
          type = lib.types.path;
          internal = true;
          description = "Default server state directory";
        };

        defaultHttpPort = lib.mkOption {
          type = lib.types.port;
          internal = true;
          description = "Default server HTTP port";
        };

        defaultGrpcPort = lib.mkOption {
          type = lib.types.port;
          internal = true;
          description = "Default server GRPC port";
        };
      };
    };
}
