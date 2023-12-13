{ lib, config, ... }:

with lib;
let
  cfg = config.dot.vpn;
  port = "1194";
  protocol = "udp";
  cipher = "AES-256-CBC";
  auth = "SHA256";
  subnet = "10.8.0";
  mask = "255.255.255.0";
in
{
  options.dot.openvpn = {
    server = {
      enable = mkEnableOption "OpenVPN server";
      host = mkOption {
        type = types.str;
        default = "host";
        example = "host";
        description = mdDoc ''
          OpenVPN server name.
        '';
      };
      domain = mkOption {
        type = types.str;
        example = "domain.com";
        description = mdDoc ''
          OpenVPN server domain.
        '';
      };
      clients = mkOption {
        type = with types; nullOr (attrsOf str);
        example = {
          client1 = "1";
        };
        description = mdDoc ''
          OpenVPN client to IP mapping.
          Masked subnet portion will be added to the front.
        '';
      };
    };
    client = {
      enable = mkEnableOption "OpenVPN client";
    };
  };

  config = mkMerge [
    (mkIf cfg.server.enable ({
      services.openvpn.servers."${cfg.server.host}".config = ''
        server ${subnet}.0 ${mask}
        port ${port}
        proto ${protocol}
        dev tun

        ca /etc/openvpn/${cfg.server.host}/root-ca.ssl.crt
        cert /etc/openvpn/${cfg.server.host}/server.ssl.crt
        key /etc/openvpn/${cfg.server.host}/server.ssl.key
        tls-auth /etc/openvpn/${cfg.server.host}/server.ta.key 0
        dh /etc/openvpn/${cfg.server.host}/server.dhparam.pem

        ifconfig-pool-persist /etc/openvpn/${cfg.server.host}/ipp.txt
        keepalive 10 120
        client-config-dir /etc/openvpn/${cfg.server.host}/clients

        cipher ${cipher}
        auth ${auth}

        user nobody
        group nogroup

        verb 3
        status /var/log/openvpn/status.log
        log-append /var/log/openvpn/openvpn.log
      '';
      sops.secrets."root-ca.ssl.crt".path = "/etc/openvpn/${cfg.server.host}/root-ca.ssl.crt";
      sops.secrets."root-ca.ssl.crt".owner = "nobody";
      sops.secrets."root-ca.ssl.crt".group = "nogroup";
      sops.secrets."root-ca.ssl.crt".mode = "0600";
      sops.secrets."server.ssl.crt".path = "/etc/openvpn/${cfg.server.host}/server.ssl.crt";
      sops.secrets."server.ssl.crt".owner = "nobody";
      sops.secrets."server.ssl.crt".group = "nogroup";
      sops.secrets."server.ssl.crt".mode = "0600";
      sops.secrets."server.ssl.key".path = "/etc/openvpn/${cfg.server.host}/server.ssl.key";
      sops.secrets."server.ssl.key".owner = "nobody";
      sops.secrets."server.ssl.key".group = "nogroup";
      sops.secrets."server.ssl.key".mode = "0600";
      sops.secrets."server.ta.key".path = "/etc/openvpn/${cfg.server.host}/server.ta.key";
      sops.secrets."server.ta.key".owner = "nobody";
      sops.secrets."server.ta.key".group = "nogroup";
      sops.secrets."server.ta.key".mode = "0600";
      sops.secrets."server.dhparam.pem".path = "/etc/openvpn/${cfg.server.host}/server.dhparam.pem";
      sops.secrets."server.dhparam.pem".owner = "nobody";
      sops.secrets."server.dhparam.pem".group = "nogroup";
      sops.secrets."server.dhparam.pem".mode = "0600";
    } // (builtins.foldl'
      (clients: client: clients // {
        environment.etc."/etc/openvpn/${cfg.server.host}/clients/${client}" = ''
          ifconfig-push ${subnet}.${cfg.server.clients."${client}"} ${mask}
        '';
      })
      ({ })
      (builtins.attrNames cfg.server.clients))
    ))
    (mkIf cfg.client.enable {
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
    })
  ];
}
