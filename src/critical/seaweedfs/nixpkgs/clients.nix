{ self, ... }:

{
  flake.nixosModules.critical-seaweedfs-nixpkgs-clients =
    {
      lib,
      config,
      pkgs,
      utils,
      ...
    }:
    let
      clients = lib.filterAttrs (_: config: config.clientConfig.enable) config.services.seaweedfs.clients;
    in
    {
      options.services.seaweedfs = {
        clients = lib.mkOption {
          description = ''SeaweedFS clients'';
          internal = true;
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                clientConfig = lib.mkOption {
                  type = lib.types.submodule {
                    imports = [ self.lib.seaweedfs.nixosSubmodules.client ];
                    freeformType = lib.types.attrsOf lib.types.raw;
                    _module.args.pkgs = pkgs;
                  };
                  description = ''SeaweedFS client configuration'';
                };

                serviceConfig = lib.mkOption {
                  # NOTE: fucking nixos...
                  type = lib.types.attrsOf utils.systemdUtils.unitOptions.unitOption;
                  default = { };
                  description = ''Extra client service config'';
                };

                command = lib.mkOption {
                  type = lib.types.str;
                  description = "SeaweedFS client command";
                };

                args = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  description = ''SeaweedFS client arguments'';
                };
              };
            }
          );
        };
      };

      config = {
        users.users = lib.mapAttrs' (name: config: {
          name = config.clientConfig.user;
          value = {
            isSystemUser = true;
            group = config.clientConfig.group;
            description = "SeaweedFS ${name} system user";
          };
        }) clients;

        users.groups = lib.mapAttrs' (name: config: {
          name = config.clientConfig.user;
          value = { };
        }) clients;

        systemd.services = lib.mapAttrs' (
          name:
          {
            clientConfig,
            serviceConfig,
            command,
            args,
          }:
          let
            securityFile = pkgs.writers.writeTOML "security.toml" clientConfig.security;
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
                  WorkingDirectory = clientConfig.stateDir;
                  StateDirectory = lib.removePrefix "/var/lib/" clientConfig.stateDir;
                  StateDirectoryMode = "0700";
                  Restart = "always";
                  User = clientConfig.user;
                  Group = clientConfig.group;
                  Environment = lib.mapAttrsToList (name: value: "${name}=${value}") clientConfig.environment;
                  EnvironmentFile = lib.mkIf (clientConfig.environmentFile != null) clientConfig.environmentFile;
                  ExecStartPre = [
                    "${pkgs.coreutils}/bin/ln -sf ${securityFile} ${clientConfig.stateDir}/security.toml"
                  ];
                  ExecStart =
                    let
                      finalArgs = lib.concatStringsSep " " (args ++ clientConfig.extraArgs);
                    in
                    "${lib.getExe clientConfig.package} ${command} ${finalArgs}";
                }
              ];
            };
          }
        ) clients;
      };
    };

  libAttrs.seaweedfs.nixosSubmodules.client =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options = {
        enable = lib.mkEnableOption "this SeaweedFS client";

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
          description = "Contents of security.toml for the client";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command line arguments";
        };

        workDir = lib.mkOption {
          type = lib.types.path;
          default = config.defaultWorkDir;
          description = "Client working directory";
        };

        stateDir = lib.mkOption {
          type = lib.types.path;
          default = config.defaultStateDir;
          description = "Client state directory";
        };

        defaultStateDir = lib.mkOption {
          type = lib.types.path;
          internal = true;
          description = "Default client state directory";
        };
      };
    };
}
