{ pkgs, lib, host, config, ... }:

# TODO: convert firewall rules to nebula firewall rules
# TODO: disable all traffic from outside vpn
# TODO: service that checks if it can reach the lighthouse - something line nebula-pre.service and nebula-pre.target
# TODO: nebula-wait-online.service and nebula-online.target

let
  hasNetwork = config.dot.hardware.network.enable;
  isCoordinator = config.dot.vpn.coordinator;
in
{
  branch.nixosModule.nixosModule = {
    options.dot = {
      vpn.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      vpn.ip = lib.mkOption {
        type = lib.types.str;
      };
      vpn.subnet.ip = lib.mkOption {
        type = lib.types.str;
      };
      vpn.subnet.bits = lib.mkOption {
        type = lib.types.ints.u16;
      };
      vpn.subnet.mask = lib.mkOption {
        type = lib.types.str;
      };
    };

    config = lib.mkIf hasNetwork {
      # NOTE: these values are not used but nix evaluates them
      services.nebula.networks.nebula = {
        enable = true;
        isLighthouse = isCoordinator;
        cert = "/etc/nebula/host.crt";
        key = "/etc/nebula/host.key";
        ca = "/etc/nebula/ca.crt";
      };
      systemd.services."nebula@nebula" = {
        after = lib.mkForce [ "basic.target" "network-online.target" ];
        wants = lib.mkForce [ "basic.target" "network-online.target" ];
        serviceConfig = {
          ExecStart = lib.mkForce "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.d";
        };
      };
      networking.firewall.allowedUDPPorts =
        lib.mkIf isCoordinator [
          4242
        ];
      environment.etc."nebula/config.d/config.yaml".text = ''
        pki:
          ca: /etc/nebula/ca.crt
          cert: /etc/nebula/host.crt
          key: /etc/nebula/host.key
        listen:
          host: '[::]'
          port: ${if isCoordinator then "4242" else "0"}
        static_map:
          cadence: 5m
          lookup_timeout: 10s
        handshakes:
          try_interval: 1s
        preferred_ranges: [ '192.168.1.0/24' ]
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
      sops.secrets."shared.vpn.ca.pub" = {
        path = "/etc/nebula/ca.crt";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0644";
      };
      sops.secrets."${host}.vpn.key.pub" = {
        path = "/etc/nebula/host.crt";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0644";
      };
      sops.secrets."${host}.vpn.key" = {
        path = "/etc/nebula/host.key";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0400";
      };
      sops.secrets."${host}.vpn.cnf" = {
        path = "/etc/nebula/config.d/lighthouse.yaml";
        owner = "nebula-nebula";
        group = "nebula-nebula";
        mode = "0400";
      };
    };
  };
}
