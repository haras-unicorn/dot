{ lib, host, config, ... }:

{
  options = {
    vpn.lighthouse.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    system = {
      services.nebula.networks.nebula.enable = true;
      systemd.services."nebula@nebula" = {
        serviceConfig = {
          ExecStart = "${config.services.nebula.networks.nebula.package}/bin/nebula -config /etc/nebula/config.d";
        };
      };
      environment.etc."nebula/config.d/config.yaml" = ''
        pki:
          ca: /etc/nebula/ca.crt
          cert: /etc/nebula/host.crt
          key: /etc/nebula/host.key
        listen:
          host: '[::]'
          port: ${if config.dot.vpn.lighthouse.enable then "4242" else "0"}
        firewall:
          outbound:
            - port: any
              proto: any
              host: any
          inbound:
            - port: any
              proto: any
              host: any
      '';
      sops.secrets."${host}.vpn.pub" = {
        path = "/etc/nebula/host.crt";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0644";
      };
      sops.secrets."${host}.vpn" = {
        path = "/etc/nebula/host.key";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0400";
      };
      sops.secrets."shared.vpn.pub" = {
        path = "/etc/nebula/ca.crt";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0644";
      };
      sops.secrets."${host}.lighthouse" = {
        path = "/etc/nebula/config.d/lighthouse.yaml";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0400";
      };

      # NOTE: default period is 5 minutes
      services.ddns-updater.enable = config.dot.vpn.lighthouse.enable;
      services.ddns-updater.environment = lib.mkIf config.dot.vpn.lighthouse.enable {
        CONFIG_FILEPATH = "/etc/ddns-updater/config.json";
      };
      users.users.ddns-updater = lib.mkIf config.dot.vpn.lighthouse.enable {
        group = "ddns-updater";
        description = "DDNS updater service user";
        isSystemUser = true;
      };
      users.groups.ddns-updater = lib.mkIf config.dot.vpn.lighthouse.enable { };
      systemd.services.ddns-updater = lib.mkIf config.dot.vpn.lighthouse.enable {
        serviceConfig = {
          DynamicUser = false;
          User = "ddns-updater";
          Group = "ddns-updater";
        };
      };
      sops.secrets."${host}.ddns" = lib.mkIf config.dot.vpn.lighthouse.enable {
        path = "/etc/ddns-updater/config.json";
        owner = "ddns-updater";
        group = "ddns-updater";
        mode = "0400";
      };
    };
  };
}
