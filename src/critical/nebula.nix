{
  pkgs,
  lib,
  config,
  ...
}:

# TODO: convert firewall rules to nebula firewall rules
# TODO: disable all traffic from outside nebula
# TODO: service that checks if it can reach the lighthouse - something line nebula-pre.service and nebula-pre.target
# TODO: nebula-wait-online.service and nebula-online.target

let
  hasNetwork = config.dot.hardware.network.enable;
  isLighthouse = config.dot.nebula.lighthouse;
  interface = "nebula-dot";
in
{
  nixosModule = {
    options.dot = {
      nebula.lighthouse = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      nebula.ip = lib.mkOption {
        type = lib.types.str;
      };
      nebula.subnet.ip = lib.mkOption {
        type = lib.types.str;
      };
      nebula.subnet.bits = lib.mkOption {
        type = lib.types.ints.u16;
      };
      nebula.subnet.mask = lib.mkOption {
        type = lib.types.str;
      };
      nebula.interface = lib.mkOption {
        type = lib.types.str;
        default = interface;
      };
    };

    config = lib.mkIf hasNetwork {
      # NOTE: these values are not used but nix evaluates them
      services.nebula.networks.dot = {
        enable = true;
        isLighthouse = isLighthouse;
        ca = config.sops.secrets."nebula-ca-public".path;
        cert = config.sops.secrets."nebula-public".path;
        key = config.sops.secrets."nebula-private".path;
      };

      systemd.services."nebula@dot" = {
        after = [
          "network-online.target"
          "chronyd-synced.target"
        ];
        requires = [
          "network-online.target"
          "chronyd-synced.target"
        ];
        serviceConfig = {
          ExecStart = lib.mkForce "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.d";
        };
      };
      systemd.targets.nebula = {
        description = "Nebula Started";
        wantedBy = [ "nebula@dot.service" ];
        after = [ "nebula@dot.service" ];
      };
      systemd.targets.nebula-online = {
        description = "Nebula Online";
        requires = [ "nebula@dot.service" ];
        after = [ "nebula@dot.service" ];
      };
      networking.firewall.allowedUDPPorts = lib.mkIf isLighthouse [
        4242
      ];
      environment.etc."nebula/config.d/config.yaml".text = ''
        pki:
          ca: ${config.sops.secrets."nebula-ca-public".path}
          cert: ${config.sops.secrets."nebula-public".path}
          key: ${config.sops.secrets."nebula-private".path}
        listen:
          host: '[::]'
          port: ${if isLighthouse then "4242" else "0"}
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
        tun:
          dev: ${config.dot.nebula.interface}
      '';

      networking.networkmanager.ensureProfiles.profiles.${config.dot.nebula.interface} = {
        connection = {
          id = config.dot.nebula.interface;
          type = "tun";
          autoconnect = true;
          interface-name = config.dot.nebula.interface;
        };
        ipv4 = {
          address1 = "${config.dot.nebula.ip}/${builtins.toString config.dot.nebula.subnet.bits}";
          method = "manual";
        };
        ipv6 = {
          method = "ignore";
        };
      };

      programs.rust-motd.settings = lib.mkIf isLighthouse {
        service_status = {
          "Nebula" = "nebula@dot";
        };
      };

      sops.secrets."nebula-ca-public" = {
        owner = "nebula-dot";
        group = "nebula-dot";
        mode = "0644";
      };
      sops.secrets."nebula-public" = {
        owner = "nebula-dot";
        group = "nebula-dot";
        mode = "0644";
      };
      sops.secrets."nebula-private" = {
        owner = "nebula-dot";
        group = "nebula-dot";
        mode = "0400";
      };
      sops.secrets."nebula-lighthouse" = {
        path = "/etc/nebula/config.d/lighthouse.yaml";
        owner = "nebula-dot";
        group = "nebula-dot";
        mode = "0400";
      };

      rumor.sops = [
        "nebula-ca-public"
        "nebula-private"
        "nebula-public"
        "nebula-lighthouse"
      ];
      rumor.specification.imports = [
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "nebula-ca-private";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "nebula-ca-public";
            allow_fail = true;
          };
        }
        {
          importer = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = if isLighthouse then "nebula-lighthouse" else "nebula-non-lighthouse";
          };
        }
        {
          importer = "copy";
          arguments = {
            from = if isLighthouse then "nebula-lighthouse" else "nebula-non-lighthouse";
            to = "nebula-lighthouse";
          };
        }
      ];
      rumor.specification.generations = [
        {
          generator = "nebula-ca";
          arguments = {
            name = "dot";
            private = "nebula-ca-private";
            public = "nebula-ca-public";
          };
        }
        {
          generator = "nebula";
          arguments = {
            ca_private = "nebula-ca-private";
            ca_public = "nebula-ca-public";
            name = config.networking.hostName;
            ip = "${config.dot.nebula.ip}/${builtins.toString config.dot.nebula.subnet.bits}";
            private = "nebula-private";
            public = "nebula-public";
          };
        }
      ];
      rumor.specification.exports = [
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "nebula-ca-private";
          };
        }
        {
          exporter = "vault-file";
          arguments = {
            path = "kv/dot/shared";
            file = "nebula-ca-public";
          };
        }
      ];
    };
  };
}
