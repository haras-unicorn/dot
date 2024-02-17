{ lib, config, ... }:

with lib;
let
  cfg = config.dot.openvpn.server;
  port = 1194;
  protocol = "tcp";
  cipher = "AES-256-CBC";
  auth = "SHA256";
  subnet = "10.8.0";
  mask = "255.255.255.0";
  dev = "tun0";
in
{
  options.dot.openvpn.server = {
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
      type = with types; lazyAttrsOf str;
      default = { };
      example = {
        client1 = "1";
      };
      description = mdDoc ''
        OpenVPN client to IP mapping.
        Masked subnet portion will be added to the front.
      '';
    };
  };

  config = mkIf cfg.enable {
    networking.nat = {
      enable = true;
      externalInterface = config.dot.hardware.networkInterface;
      internalInterfaces = [ dev ];
    };
    networking.firewall.trustedInterfaces = [ dev ];
    networking.firewall.allowedUDPPorts = [ port ];
    networking.firewall.allowedTCPPorts = [ port ];
    services.openvpn.servers."${cfg.host}".config = ''
      server ${subnet}.0 ${mask}
      port ${builtin.toString port}
      proto ${protocol}
      dev ${dev}

      ca /etc/openvpn/${cfg.host}/root-ca.ssl.crt
      cert /etc/openvpn/${cfg.host}/server.ssl.crt
      key /etc/openvpn/${cfg.host}/server.ssl.key
      tls-auth /etc/openvpn/${cfg.host}/server.ta.key 0
      dh /etc/openvpn/${cfg.host}/server.dhparam.pem

      ifconfig-pool-persist /etc/openvpn/${cfg.host}/ipp.txt
      keepalive 10 120
      client-config-dir /etc/openvpn/${cfg.host}/clients

      cipher ${cipher}
      auth ${auth}

      user nobody
      group nogroup

      verb 4
      status /var/log/openvpn/status.log
      log-append /var/log/openvpn/openvpn.log
    '';
    sops.secrets."root-ca.ssl.crt".path = "/etc/openvpn/${cfg.host}/root-ca.ssl.crt";
    sops.secrets."root-ca.ssl.crt".owner = "nobody";
    sops.secrets."root-ca.ssl.crt".group = "nogroup";
    sops.secrets."root-ca.ssl.crt".mode = "0600";
    sops.secrets."server.ssl.crt".path = "/etc/openvpn/${cfg.host}/server.ssl.crt";
    sops.secrets."server.ssl.crt".owner = "nobody";
    sops.secrets."server.ssl.crt".group = "nogroup";
    sops.secrets."server.ssl.crt".mode = "0600";
    sops.secrets."server.ssl.key".path = "/etc/openvpn/${cfg.host}/server.ssl.key";
    sops.secrets."server.ssl.key".owner = "nobody";
    sops.secrets."server.ssl.key".group = "nogroup";
    sops.secrets."server.ssl.key".mode = "0600";
    sops.secrets."server.ta.key".path = "/etc/openvpn/${cfg.host}/server.ta.key";
    sops.secrets."server.ta.key".owner = "nobody";
    sops.secrets."server.ta.key".group = "nogroup";
    sops.secrets."server.ta.key".mode = "0600";
    sops.secrets."server.dhparam.pem".path = "/etc/openvpn/${cfg.host}/server.dhparam.pem";
    sops.secrets."server.dhparam.pem".owner = "nobody";
    sops.secrets."server.dhparam.pem".group = "nogroup";
    sops.secrets."server.dhparam.pem".mode = "0600";

    environment.etc = attrsets.concatMapAttrs
      (client: ip: {
        "/openvpn/${cfg.host}/clients/${client}".text = ''
          ifconfig-push ${subnet}.${ip} ${mask}
        '';
      })
      cfg.clients;
  };
}
