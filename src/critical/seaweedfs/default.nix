# TODO: security

{
  flake.homeModules.critical-seaweedfs =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    lib.mkIf hasNetwork {
    };

  flake.nixosModules.critical-seaweedfs =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      hosts = builtins.filter (
        host:
        if lib.hasAttrByPath [ "system" "dot" "seaweedfs" "enable" ] host then
          host.system.dot.seaweedfs.enable
        else
          false
      ) config.dot.host.hosts;

      peers = builtins.map (
        host:
        let
          masterCfg = host.system.services.seaweedfs.master;
          ip = masterCfg.ip;
          port = masterCfg.httpPort;
        in
        "${ip}:${builtins.toString port}"
      ) (builtins.filter (host: host.name != config.dot.host.name) hosts);

      masters = builtins.map (
        host:
        let
          masterCfg = host.system.services.seaweedfs.master;
          ip = masterCfg.ip;
          port = masterCfg.httpPort;
        in
        "${ip}:${builtins.toString port}"
      ) hosts;
    in
    {
      options.dot = {
        seaweedfs = {
          enable = lib.mkEnableOption "SeaweedFS";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.seaweedfs.enable) {
        services.seaweedfs.master.enable = true;
        services.seaweedfs.master.openFirewall = true;
        services.seaweedfs.master.ip = config.dot.host.ip;
        services.seaweedfs.master.peers = peers;
        systemd.services."seaweedfs-master".requires = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];
        systemd.services."seaweedfs-master".after = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];

        services.seaweedfs.volumes.dot.enable = true;
        # TODO: remove mention of cockroachdb here
        # NOTE: 8080 is cockroachdb
        services.seaweedfs.volumes.dot.httpPort = 8081;
        services.seaweedfs.volumes.dot.ip = config.dot.host.ip;
        services.seaweedfs.volumes.dot.masterServers = masters;
        services.seaweedfs.volumes.dot.openFirewall = true;
        services.seaweedfs.volumes.dot.dataCenter = config.dot.locality.dataCenter;
        services.seaweedfs.volumes.dot.rack = config.dot.locality.rack;
        systemd.services."seaweedfs-volume@dot".requires = [ "seaweedfs-master.service" ];
        systemd.services."seaweedfs-volume@dot".after = [ "seaweedfs-master.service" ];

        services.seaweedfs.filers.dot.enable = true;
        services.seaweedfs.filers.dot.ip = config.dot.host.ip;
        services.seaweedfs.filers.dot.masterServers = masters;
        services.seaweedfs.filers.dot.openFirewall = true;
        services.seaweedfs.filers.dot.environmentFile = config.sops.secrets."seaweedfs-filer-env".path;
        services.seaweedfs.filers.dot.dataCenter = config.dot.locality.dataCenter;
        services.seaweedfs.filers.dot.rack = config.dot.locality.rack;
        # TODO: remove mention of postgres here
        # TODO: ssl certs like this
        # sslmode = "verify-full"
        # sslcert = "/path/to/client.crt"
        # sslkey = "/path/to/client.key"
        # sslrootcert = "/path/to/ca.crt"
        services.seaweedfs.filers.dot.config.postgres = {
          enabled = true;
          hostname = config.dot.database.host;
          port = config.dot.database.port;
          username = config.dot.database.instances.seaweedfs.user;
          database = config.dot.database.instances.seaweedfs.name;
        };
        systemd.services."seaweedfs-filer@dot".requires = [
          "seaweedfs-master.service"
          "dot-database-initialized.target"
        ];
        systemd.services."seaweedfs-filer@dot".after = [
          "seaweedfs-master.service"
          "dot-database-initialized.target"
        ];

        environment.systemPackages = [
          pkgs.seaweedfs
        ];

        # NOTE: something is needed just so the mounts work properly
        users.users.seaweedfs.uid = 18888;
        users.groups.seaweedfs.gid = 18888;

        dot.database.apps.seaweedfs = {
          hosts = builtins.map ({ name, ... }: name) hosts;
          user = config.services.seaweedfs.filers.dot.user;
          group = config.services.seaweedfs.filers.dot.group;
          init.sql.script = ''
            create table if not exists filemeta (
              dirhash     bigint,
              name        varchar(65535),
              directory   varchar(65535),
              meta        bytea,
              primary key (dirhash, name)
            );
          '';
        };

        dot.services = [
          {
            name = "seaweedfs-master";
            port = config.services.seaweedfs.master.httpPort;
            health = "http://";
          }
          {
            name = "seaweedfs-volume";
            port = config.services.seaweedfs.volumes.dot.httpPort;
            health = "http:///status";
          }
          {
            name = "seaweedfs-filer";
            port = config.services.seaweedfs.filers.dot.httpPort;
            health = "http://";
          }
        ];

        sops.secrets."seaweedfs-filer-env" = {
          owner = config.services.seaweedfs.filers.dot.user;
          group = config.services.seaweedfs.filers.dot.group;
          mode = "0400";
        };
        rumor.sops.keys = [
          "seaweedfs-filer-env"
        ];
        rumor.specification.generations = lib.mkAfter [
          {
            generator = "env";
            arguments = {
              name = "seaweedfs-filer-env";
              renew = true;
              variables = {
                # TODO: remove mention of postgres here
                WEED_POSTGRES_PASSWORD = config.dot.database.instances.seaweedfs.passwordSecret;
              };
            };
          }
        ];
      };
    };
}
