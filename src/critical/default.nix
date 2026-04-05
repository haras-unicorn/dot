{
  flake.nixosModules.critical =
    { lib, config, ... }:
    {
      options.dot = {
        critical = {
          enable = lib.mkEnableOption "Critical services";
        };
      };

      config = lib.mkIf config.dot.critical.enable {
        dot.nebula.enableLighthouseAndRelay = true;
        dot.ddns-updater.enable = true;
        dot.consul.enable = true;
        dot.traefik.enable = true;
        dot.cockroachdb.enable = true;
        dot.cockroachdb.enableBuiltinBackup = true;
        dot.seaweedfs.enable = true;
        dot.vault.enable = true;
        dot.vaultwarden.enable = true;
        dot.miniflux.enable = true;
        dot.backup.enable = true;
      };
    };
}
