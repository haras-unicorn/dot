{ lib, config, ... }:

let
  cfg = config.dot.openvpn.client;
  port = 1194;
  protocol = "udp";
  cipher = "AES-256-CBC";
  auth = "SHA256";
  dev = "tun0";
in
{
  options.dot.openvpn.client = {
    host = lib.mkOption {
      type = lib.types.str;
      default = "host";
      example = "host";
      description = lib.mdDoc ''
        OpenVPN server name.
      '';
    };
    domain = lib.mkOption {
      type = lib.types.str;
      example = "domain.com";
      description = lib.mdDoc ''
        OpenVPN server domain.
      '';
    };
  };

  config = {
    system = {
      services.openvpn.servers."${cfg.host}" = {
        config = ''
          client
          remote ${cfg.domain} ${builtins.toString port}
          proto ${protocol}
          dev ${dev}

          ca /etc/openvpn/${cfg.host}/root-ca.ssl.crt
          cert /etc/openvpn/${cfg.host}/client.ssl.crt
          key /etc/openvpn/${cfg.host}/client.ssl.key
          # tls-auth /etc/openvpn/${cfg.host}/server.ta.key 1

          resolv-retry infinite
          nobind

          cipher ${cipher}
          auth ${auth}
          # remote-cert-tls server

          script-security 2

          verb 4
        '';
      };
      sops.secrets."root-ca.ssl.crt".path = "/etc/openvpn/${cfg.host}/root-ca.ssl.crt";
      sops.secrets."root-ca.ssl.crt".owner = "nobody";
      sops.secrets."root-ca.ssl.crt".group = "nogroup";
      sops.secrets."root-ca.ssl.crt".mode = "0600";
      sops.secrets."client.ssl.crt".path = "/etc/openvpn/${cfg.host}/client.ssl.crt";
      sops.secrets."client.ssl.crt".owner = "nobody";
      sops.secrets."client.ssl.crt".group = "nogroup";
      sops.secrets."client.ssl.crt".mode = "0600";
      sops.secrets."client.ssl.key".path = "/etc/openvpn/${cfg.host}/client.ssl.key";
      sops.secrets."client.ssl.key".owner = "nobody";
      sops.secrets."client.ssl.key".group = "nogroup";
      sops.secrets."client.ssl.key".mode = "0600";
      sops.secrets."server.ta.key".path = "/etc/openvpn/${cfg.host}/server.ta.key";
      sops.secrets."server.ta.key".owner = "nobody";
      sops.secrets."server.ta.key".group = "nogroup";
      sops.secrets."server.ta.key".mode = "0600";
    };
  };
}
