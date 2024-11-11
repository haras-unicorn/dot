{ pkgs, lib, host, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
in
{
  options = {
    vpn.lighthouse.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = {
    system = lib.mkIf hasNetwork {
      # NOTE: these values are not used but nix evaluates them for some reason
      services.nebula.networks.nebula = {
        enable = true;
        isLighthouse = config.dot.vpn.lighthouse.enable;
        cert = "/etc/nebula/host.crt";
        key = "/etc/nebula/host.key";
        ca = "/etc/nebula/ca.crt";
      };
      systemd.services."nebula@nebula" = {
        serviceConfig = {
          ExecStart = lib.mkForce "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.d";
        };
      };
      networking.firewall.allowedUDPPorts =
        lib.mkIf config.dot.vpn.lighthouse.enable [
          4242
        ];
      environment.etc."nebula/config.d/config.yaml".text = ''
        pki:
          ca: /etc/nebula/ca.crt
          cert: /etc/nebula/host.crt
          key: /etc/nebula/host.key
        listen:
          host: '[::]'
          port: ${if config.dot.vpn.lighthouse.enable then "4242" else "0"}
        static_map:
          cadence: 5m
          lookup_timeout: 10s
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
          DynamicUser = lib.mkForce false;
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

    home = lib.mkIf (hasNetwork && hasMonitor) {
      xdg.desktopEntries = {
        ddns-updater = {
          name = "DDNS Updater";
          exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin} --new-window localhost:8000";
          terminal = false;
        };
      };
    };
  };
}
