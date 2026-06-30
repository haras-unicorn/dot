{
  machines.nixosModules.chronyd =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      services.timesyncd.enable = false;

      networking.timeServers = [
        # Google
        "216.239.35.0"
        "216.239.35.4"
        "216.239.35.8"
        "216.239.35.12"

        # Cloudflare
        "162.159.200.1"
        "162.159.200.123"
      ];

      services.chrony.enable = true;
    };
}
