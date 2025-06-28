{ config, lib, pkgs, ... }:

let
  cfg = config.services.seaweedfs;

  mkSeaweedService = name: componentCfg: serviceConfig: args: {
    description = "SeaweedFS ${name}";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    serviceConfig = {
      User = componentCfg.user;
      Group = componentCfg.group;
      Environment = lib.mapAttrsToList
        (name: value: "${name}=${value}")
        componentCfg.environment;
      EnvironmentFile = lib.mkIf
        (componentCfg.environmentFile != null)
        componentCfg.environmentFile;
      ExecStart =
        let
          finalArgs =
            lib.concatStringsSep " "
              (args ++ componentCfg.extraArgs);
        in
        "${pkgs.seaweedfs}/bin/weed ${name} ${finalArgs}";
    } // serviceConfig;
  };

  componentOptions = {
    enable = lib.mkEnableOption "this SeaweedFS component";

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
      description = "Whether to open firewall for this component";
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

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command line arguments";
    };
  };

in
{
  branch.nixosModule.nixosModule = {
    options.services.seaweedfs = {
      enable = lib.mkEnableOption "SeaweedFS distributed storage";

      master = componentOptions // {
        workDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/seaweedfs/master";
          description = "Master working directory needed for setting up security.toml";
        };

        dataDir = lib.mkOption {
          type = lib.types.path;
          default = "${cfg.master.workDir}/data";
          description = "Master data directory";
        };

        ip = lib.mkOption {
          type = lib.types.str;
          description = "Master server IP";
          example = "192.168.1.10";
        };

        httpPort = lib.mkOption {
          type = lib.types.port;
          default = 9333;
          description = "Master HTTP port";
        };

        grpcPort = lib.mkOption {
          type = lib.types.port;
          default = 19333;
          description = "Master gRPC port";
        };

        peers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of master peers (host:(httpPort(.grpcPort)?)?)";
          example = [ "192.168.1.10" "192.168.1.11:9333" "192.168.1.11:9333.19333" ];
        };

        security = lib.mkOption {
          type = lib.types.anything;
          default = { };
          description = "Contents of security.toml for the master server";
        };
      };

      volumes = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ config, name, ... }: {
          options = componentOptions // {
            workDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/seaweedfs/volumes/${name}";
              description = "Volume working directory needed for setting up security.toml";
            };

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "${config.workDir}/data";
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

            ip = lib.mkOption {
              type = lib.types.str;
              description = "Volume server IP";
              example = "192.168.1.10";
            };

            httpPort = lib.mkOption {
              type = lib.types.port;
              default = 8080;
              description = "Volume HTTP port";
            };

            grpcPort = lib.mkOption {
              type = lib.types.port;
              default = 18080;
              description = "Volume gRPC port";
            };

            masterServers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of master servers (host:(httpPort(.grpcPort)?)?)";
            };

            security = lib.mkOption {
              type = lib.types.anything;
              default = { };
              description = "Contents of security.toml for the volume server";
            };
          };
        }));
        default = { };
        description = "Volume server instances";
      };

      filers = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
          options = componentOptions // {
            workDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/seaweedfs/filers/${name}";
              description = "Filer working directory needed for setting up security.toml and filer.toml";
            };

            dataCenter = lib.mkOption {
              type = lib.types.str;
              description = "Filer server data center location";
            };

            rack = lib.mkOption {
              type = lib.types.str;
              description = "Filer server rack location";
            };

            ip = lib.mkOption {
              type = lib.types.str;
              description = "Filer server IP";
              example = "192.168.1.10";
            };

            httpPort = lib.mkOption {
              type = lib.types.port;
              default = 8888;
              description = "Filer HTTP port";
            };

            grpcPort = lib.mkOption {
              type = lib.types.port;
              default = 18888;
              description = "Filer gRPC port";
            };

            masterServers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "List of master servers (host:(httpPort(.grpcPort)?)?)";
            };

            security = lib.mkOption {
              type = lib.types.anything;
              default = { };
              description = "Contents of security.toml for the filer server";
            };

            config = lib.mkOption {
              type = lib.types.anything;
              default = { };
              description = "Contents of filer.toml for the filer server";
            };
          };
        }));
        default = { };
        description = "Filer server instances";
      };
    };

    config = lib.mkIf cfg.enable {
      users.users.seaweedfs = {
        isSystemUser = true;
        group = "seaweedfs";
        description = "SeaweedFS system user";
      };

      users.groups.seaweedfs = { };

      systemd.services = lib.mkMerge [
        {
          seaweedfs-master = lib.mkIf cfg.master.enable
            (mkSeaweedService
              "master"
              cfg.master
              {
                WorkingDirectory = cfg.master.workDir;
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/ln -sf /etc/seaweedfs/master/security.toml ${cfg.master.workDir}/security.toml"
                ];
              }
              [
                "-ip=${cfg.master.ip}"
                "-port=${toString cfg.master.httpPort}"
                "-port.grpc=${toString cfg.master.grpcPort}"
                "-mdir=${cfg.master.dataDir}"
                "-peers=${lib.concatStringsSep "," cfg.master.peers}"
              ]);
        }
        (lib.mapAttrs'
          (name: volumeCfg: lib.nameValuePair "seaweedfs-volume@${name}"
            (mkSeaweedService
              "volume"
              volumeCfg
              {
                WorkingDirectory = volumeCfg.workDir;
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/ln -sf /etc/seaweedfs/volumes/${name}/security.toml ${volumeCfg.workDir}/security.toml"
                ];
              }
              [
                "-dataCenter=${volumeCfg.dataCenter}"
                "-rack=${volumeCfg.rack}"
                "-max=${volumeCfg.max}"
                "-ip=${volumeCfg.ip}"
                "-port=${toString volumeCfg.httpPort}"
                "-port.grpc=${toString volumeCfg.grpcPort}"
                "-mserver=${lib.concatStringsSep "," volumeCfg.masterServers}"
              ]))
          (lib.filterAttrs (_: v: v.enable) cfg.volumes))
        (lib.mapAttrs'
          (name: filerCfg: lib.nameValuePair "seaweedfs-filer@${name}"
            (mkSeaweedService
              "filer"
              filerCfg
              {
                WorkingDirectory = filerCfg.workDir;
                ExecStartPre = [
                  "${pkgs.coreutils}/bin/ln -sf /etc/seaweedfs/filers/${name}/security.toml ${filerCfg.workDir}/security.toml"
                  "${pkgs.coreutils}/bin/ln -sf /etc/seaweedfs/filers/${name}/filer.toml ${filerCfg.workDir}/filer.toml"
                ];
              }
              [
                "-dataCenter=${filerCfg.dataCenter}"
                "-rack=${filerCfg.rack}"
                "-ip=${filerCfg.ip}"
                "-port=${toString filerCfg.httpPort}"
                "-port.grpc=${toString filerCfg.grpcPort}"
                "-master=${lib.concatStringsSep "," filerCfg.masterServers}"
              ]))
          (lib.filterAttrs (_: v: v.enable) cfg.filers))
      ];

      environment.etc = lib.mkMerge [
        (lib.optionalAttrs (cfg.master.enable && cfg.master.security != { }) {
          "seaweedfs/master/security.toml" = {
            source = pkgs.writers.writeTOML "security.toml" cfg.master.security;
            user = cfg.master.user;
            group = cfg.master.group;
            mode = "0644";
          };
        })
        (lib.mapAttrs'
          (name: volumeCfg: lib.nameValuePair "seaweedfs/volumes/${name}/security.toml" {
            source = pkgs.writers.writeTOML "security.toml" volumeCfg.security;
            user = volumeCfg.user;
            group = volumeCfg.group;
            mode = "0644";
          })
          (lib.filterAttrs (_: v: v.enable && v.security != { }) cfg.volumes))
        (lib.mapAttrs'
          (name: filerCfg: lib.nameValuePair "seaweedfs/filers/${name}/security.toml" {
            source = pkgs.writers.writeTOML "security.toml" filerCfg.security;
            user = filerCfg.user;
            group = filerCfg.group;
            mode = "0644";
          })
          (lib.filterAttrs (_: v: v.enable && v.security != { }) cfg.filers))
        (lib.mapAttrs'
          (name: filerCfg: lib.nameValuePair "seaweedfs/filers/${name}/filer.toml" {
            source = pkgs.writers.writeTOML "filer.toml" filerCfg.config;
            user = filerCfg.user;
            group = filerCfg.group;
            mode = "0644";
          })
          (lib.filterAttrs (_: v: v.enable && v.config != { }) cfg.filers))
      ];

      systemd.tmpfiles.rules = lib.mkMerge [
        (lib.optionals cfg.master.enable [
          "d ${cfg.master.workDir} 0750 ${cfg.master.user} ${cfg.master.group} -"
          "d ${cfg.master.dataDir} 0750 ${cfg.master.user} ${cfg.master.group} -"
        ])
        (lib.flatten (lib.mapAttrsToList
          (name: volumeCfg: lib.optionals volumeCfg.enable [
            "d ${volumeCfg.workDir} 0750 ${volumeCfg.user} ${volumeCfg.group} -"
            "d ${volumeCfg.dataDir} 0750 ${volumeCfg.user} ${volumeCfg.group} -"
          ])
          cfg.volumes))
        (lib.flatten (lib.mapAttrsToList
          (name: filerCfg: lib.optionals filerCfg.enable [
            "d ${filerCfg.workDir} 0750 ${filerCfg.user} ${filerCfg.group} -"
          ])
          cfg.filers))
      ];

      networking.firewall.allowedTCPPorts = lib.mkMerge
        ([
          (lib.optionals
            (cfg.master.enable && cfg.master.openFirewall)
            [ cfg.master.httpPort cfg.master.grpcPort ])
        ]
        ++ (builtins.map
          (volume: lib.optionals
            (volume.enable && volume.openFirewall)
            [ volume.httpPort volume.grpcPort ])
          (lib.attrValues cfg.volumes))
        ++ (builtins.map
          (filer: lib.optionals
            (filer.enable && filer.openFirewall)
            [ filer.httpPort filer.grpcPort ])
          (lib.attrValues cfg.filers)));
    };
  };
}
