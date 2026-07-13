{
  machines.nixosModules.coredns =
    { lib, config, ... }:
    let
      hardware = config.dot.hardware;

      forwards = builtins.concatStringsSep " " [
        # Cloudflare
        "tls://1.1.1.2%one.one.one.one"
        "tls://1.0.0.2%one.one.one.one"

        # Quad9
        "tls://9.9.9.9%dns.quad9.net"

        # ControlD
        "tls://76.76.2.11%p1.freedns.controld.com"
      ];
    in
    lib.mkIf hardware.network {
      services.resolved.enable = false;

      networking.networkmanager.dns = "none";
      networking.nameservers = [ "127.0.0.1" ];

      services.coredns = {
        enable = true;
        config = ''
          . {
            bind 127.0.0.1
            dnssec
            cache
            forward . ${forwards}
          }
        '';
      };
    };
}
