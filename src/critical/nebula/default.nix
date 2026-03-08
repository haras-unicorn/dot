{ self, ... }:

# TODO: convert firewall rules to nebula firewall rules
# TODO: disable all traffic from outside nebula
# TODO: service that checks if it can reach the lighthouse - something line nebula-pre.service and nebula-pre.target
# TODO: nebula-wait-online.service and dot-network-online.target

{
  dot.network.subnet = {
    prefix = "10.69.42";
    ip = "10.69.42.0";
    bits = 24;
    mask = "255.255.255.0";
  };

  flake.nixosModules.critical-nebula =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      isLighthouseAndRelay = config.dot.nebula.enableLighthouseAndRelay;
    in
    {
      options.dot = {
        nebula = {
          enable = lib.mkEnableOption "Nebula VPN";

          enableLighthouseAndRelay = lib.mkEnableOption "Nebula VPN lighthouse and relay";
        };
      };

      config = lib.mkMerge [
        { dot.nebula.enable = lib.mkDefault hasNetwork; }
        (lib.mkIf (hasNetwork && config.dot.nebula.enable) {
          # NOTE: these values are not used but nix evaluates them
          services.nebula.networks.dot = {
            enable = true;
            isLighthouse = isLighthouseAndRelay;
            ca = config.sops.secrets."nebula-ca-public".path;
            cert = config.sops.secrets."nebula-public".path;
            key = config.sops.secrets."nebula-private".path;
          };

          systemd.services."nebula@dot" = {
            wantedBy = [
              "network-online.target"
              "dot-time-synchronized.target"
            ];
            after = [
              "network-online.target"
              "dot-time-synchronized.target"
            ];
            requires = [
              "network-online.target"
              "dot-time-synchronized.target"
            ];
            serviceConfig = {
              ExecStart = lib.mkForce "${pkgs.nebula}/bin/nebula -config /etc/nebula/config.d";
              ExecStartPost = lib.mkForce "${pkgs.bash}/bin/bash -c 'sleep 1 && ${pkgs.networkmanager}/bin/nmcli c up ${config.dot.host.interface} || true'";
              Restart = lib.mkForce "always";
            };
          };
          systemd.targets.dot-network-online = {
            wantedBy = [ "nebula@dot.service" ];
            bindsTo = [ "nebula@dot.service" ];
            after = [ "nebula@dot.service" ];
          };
          networking.firewall.allowedUDPPorts = lib.mkIf isLighthouseAndRelay [
            4242
          ];
          environment.etc."nebula/config.d/config.yaml".text = ''
            pki:
              ca: ${config.sops.secrets."nebula-ca-public".path}
              cert: ${config.sops.secrets."nebula-public".path}
              key: ${config.sops.secrets."nebula-private".path}
            listen:
              host: '[::]'
              port: ${if isLighthouseAndRelay then "4242" else "0"}
            static_map:
              cadence: 5m
              lookup_timeout: 10s
            handshakes:
              try_interval: 1s
            preferred_ranges: [ '192.168.0.0/16' ]
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
              dev: ${config.dot.host.interface}
          '';

          networking.networkmanager.ensureProfiles.profiles.${config.dot.host.interface} = {
            connection = {
              id = config.dot.host.interface;
              type = "tun";
              autoconnect = true;
              interface-name = config.dot.host.interface;
            };
            ipv4 = {
              address1 = "${config.dot.host.ip}/${builtins.toString config.dot.network.subnet.bits}";
              method = "manual";
            };
            ipv6 = {
              method = "ignore";
            };
          };

          programs.rust-motd.settings = lib.mkIf isLighthouseAndRelay {
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

          cryl.sops.keys = [
            "nebula-ca-public"
            "nebula-private"
            "nebula-public"
            "nebula-lighthouse"
          ];
          cryl.specification.imports = [
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.cryl.shared;
                file = "nebula-ca-private";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.cryl.shared;
                file = "nebula-ca-public";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.cryl.shared;
                file = if isLighthouseAndRelay then "nebula-lighthouse" else "nebula-non-lighthouse";
              };
            }
            {
              importer = "copy";
              arguments = {
                from = if isLighthouseAndRelay then "nebula-lighthouse" else "nebula-non-lighthouse";
                to = "nebula-lighthouse";
              };
            }
          ];
          cryl.specification.generations = [
            {
              generator = "nebula-ca";
              arguments = {
                name = "dot";
                private = "nebula-ca-private";
                public = "nebula-ca-public";
              };
            }
            {
              generator = "nebula-cert";
              arguments = {
                ca_private = "nebula-ca-private";
                ca_public = "nebula-ca-public";
                name = config.dot.host.name;
                ip = "${config.dot.host.ip}/${builtins.toString config.dot.network.subnet.bits}";
                private = "nebula-private";
                public = "nebula-public";
              };
            }
          ];
          cryl.specification.exports = [
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.cryl.shared;
                file = "nebula-ca-private";
              };
            }
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.cryl.shared;
                file = "nebula-ca-public";
              };
            }
          ];
        })
      ];
    };
}
