{
  machines.nixosModules.coredns =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;
    in
    lib.mkIf hardware.network {
      services.resolved.enable = false;

      networking.networkmanager.dns = "none";
      networking.nameservers = [ "127.0.0.1" ];

      services.coredns = {
        enable = true;
        # NOTE: Cloudflare and Google
        config = ''
          . {
            bind 127.0.0.1
            forward . 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
          }
        '';
      };
    };
}
