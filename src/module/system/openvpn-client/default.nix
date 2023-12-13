{ lib, config, ... }:

with lib;
let
  cfg = config.dot.openvpn;
  port = "1194";
  protocol = "udp";
  cipher = "AES-256-CBC";
  auth = "SHA256";
  subnet = "10.8.0";
  mask = "255.255.255.0";
in
{
  options.dot.openvpn.client = {
    enable = mkEnableOption "OpenVPN client";
  };

  config = mkIf cfg.client.enable {
    services.openvpn.servers."${cfg.server.host}".config = ''
      client
      remote ${cfg.server.domain} ${port}
      proto ${protocol}
      dev tun

      ca /etc/openvpn/${cfg.server.host}/root-ca.ssl.crt
      cert /etc/openvpn/${cfg.server.host}/client.ssl.crt
      key /etc/openvpn/${cfg.server.host}/client.ssl.key
      tls-auth /etc/openvpn/${cfg.server.host}/server.ta.key 1

      resolv-retry infinite
      nobind

      cipher ${cipher}
      auth ${auth}
      remote-cert-tls server

      script-security 2
      up /etc/openvpn/update-resolv-conf
      down /etc/openvpn/update-resolv-conf

      verb 3
    '';
    sops.secrets."root-ca.ssl.crt".path = "/etc/openvpn/${cfg.server.host}/root-ca.ssl.crt";
    sops.secrets."root-ca.ssl.crt".owner = "nobody";
    sops.secrets."root-ca.ssl.crt".group = "nogroup";
    sops.secrets."root-ca.ssl.crt".mode = "0600";
    sops.secrets."client.ssl.crt".path = "/etc/openvpn/${cfg.server.host}/client.ssl.crt";
    sops.secrets."client.ssl.crt".owner = "nobody";
    sops.secrets."client.ssl.crt".group = "nogroup";
    sops.secrets."client.ssl.crt".mode = "0600";
    sops.secrets."client.ssl.key".path = "/etc/openvpn/${cfg.server.host}/client.ssl.key";
    sops.secrets."client.ssl.key".owner = "nobody";
    sops.secrets."client.ssl.key".group = "nogroup";
    sops.secrets."client.ssl.key".mode = "0600";
    sops.secrets."server.ta.key".path = "/etc/openvpn/${cfg.server.host}/server.ta.key";
    sops.secrets."server.ta.key".owner = "nobody";
    sops.secrets."server.ta.key".group = "nogroup";
    sops.secrets."server.ta.key".mode = "0600";
  };
}
