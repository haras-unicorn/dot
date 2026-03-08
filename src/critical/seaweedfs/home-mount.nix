{
  flake.nixosModules.critical-seaweedfs-home-mount =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      hosts = (
        builtins.filter (
          x:
          if lib.hasAttrByPath [ "system" "dot" "seaweedfs" "enable" ] x then
            x.system.dot.seaweedfs.enable
          else
            false
        ) config.dot.host.hosts
      );

      mountDir = "${config.dot.host.home}/weed";
    in
    {
      options.dot = {
        seaweedfs = {
          enableHomeMount = lib.mkEnableOption "SeaweedFS home mount";
        };
      };

      config = lib.mkIf (hasNetwork && config.dot.seaweedfs.enableHomeMount) {
        services.seaweedfs.mounts.dot.enable = true;
        services.seaweedfs.mounts.dot.mountDir = mountDir;
        services.seaweedfs.mounts.dot.mountUid = config.dot.host.uid;
        services.seaweedfs.mounts.dot.mountGid = config.dot.host.gid;
        services.seaweedfs.mounts.dot.filerPath = mountDir;
        services.seaweedfs.mounts.dot.filers = builtins.map (
          host:
          let
            filerConfig = host.system.services.seaweedfs.filers.dot;
            ip = filerConfig.ip;
            port = filerConfig.httpPort;

            filerUid = host.system.users.users.${filerConfig.user}.uid;
            filerGid = host.system.users.groups.${filerConfig.group}.gid;
          in
          {
            server = "${ip}:${builtins.toString port}";
            uid = filerUid;
            gid = filerGid;
          }
        ) hosts;
        systemd.services."seaweedfs-mount@dot".wantedBy = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];
        systemd.services."seaweedfs-mount@dot".after = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];
        systemd.services."seaweedfs-mount@dot".requires = [
          "dot-network-online.target"
          "dot-time-synchronized.target"
        ];
      };
    };
}
