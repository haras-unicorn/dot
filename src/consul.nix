{ pkgs, lib, config, ... }:

let
  hasNetwork = config.dot.hardware.network.enable;
  hasMonitor = config.dot.hardware.monitor.enable;
  etc = "/etc/consul";
  certs = "${etc}/certs";
  # NOTE: consul complains how it must end with .json or .hcl
  configPath = "${etc}/config.json";
  port = 8500;
  rpcPort = 8300;
  serfLanPort = 8301;
  serfWanPort = 8302;
  grpcTlsPort = 8503;
  dnsPort = 53;
  hosts = builtins.map
    (x: x.ip)
    (builtins.filter
      (x:
        if lib.hasAttrByPath [ "system" "dot" "consul" "coordinator" ] x
        then x.system.dot.consul.coordinator
        else false)
      config.dot.hosts);
  firstHost = builtins.head hosts;
  consoleAddress = "https://${firstHost}:${builtins.toString port}";
  retryJoinHosts = builtins.filter (x: x != config.dot.host.ip) hosts;
in
{
  branch.homeManagerModule.homeManagerModule = lib.mkIf hasNetwork {
    home.packages = [
      pkgs.consul
    ];

    xdg.desktopEntries = lib.mkIf hasMonitor {
      consul = {
        name = "Consul";
        exec = "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
          + " --new-window ${consoleAddress}";
        terminal = false;
      };
    };
  };

  branch.nixosModule.nixosModule = {
    options.dot = {
      consul.coordinator = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      consul.services = lib.mkOption {
        type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        default = [ ];
      };
    };

    config = lib.mkMerge [
      (lib.mkIf (hasNetwork && !config.dot.consul.coordinator) {
        networking.nameservers = hosts;
      })
      (lib.mkIf (hasNetwork && config.dot.consul.coordinator) {
        networking.nameservers = [ "127.0.0.1" ];

        systemd.services.consul.after = [ "vpn-online.target" "time-synced.target" ];
        systemd.services.consul.requires = [ "vpn-online.target" "time-synced.target" ];

        services.consul.enable = true;
        services.consul.webUi = true;
        services.consul.dropPrivileges = false;

        services.consul.extraConfig = {
          datacenter = "dot";
          node_name = config.dot.host.name;
          server = true;
          bootstrap_expect = builtins.length hosts;
          retry_join = retryJoinHosts;
          # NOTE: not on "0.0.0.0" because resolved has "127.0.0.53:53"
          client_addr = config.dot.host.ip;
          # NOTE: like this instead of through nixpkgs
          # because then it tries to wait for the device
          # but vpn doesn't work that way
          bind_addr = config.dot.host.ip;
          advertise_addr = config.dot.host.ip;

          ui_config = {
            enabled = true;
          };

          connect = {
            enabled = true;
          };

          log_level = "INFO";
          enable_syslog = true;

          encrypt_verify_incoming = true;
          encrypt_verify_outgoing = true;

          acl.enabled = false;
          # acl = {
          #   enabled = true;
          #   default_policy = "deny";
          #   enable_token_persistence = true;
          # };

          tls = {
            defaults = {
              verify_incoming = true;
              verify_outgoing = true;
              ca_file = "${certs}/ca.crt";
              cert_file = "${certs}/consul.crt";
              key_file = "${certs}/consul.key";
            };
            https = {
              verify_incoming = false;
            };
          };

          ports = {
            http = -1;
            https = port;
            dns = dnsPort;
            grpc = -1;
            grpc_tls = grpcTlsPort;
            serf_lan = serfLanPort;
            serf_wan = serfWanPort;
            server = rpcPort;
          };

          services = config.dot.consul.services;
        };

        dot.consul.services = [{
          name = "consul";
          port = port;
          address = config.dot.host.ip;
          tags = [
            "dot.enable=true"
          ];
          check = {
            http = "http://${config.dot.host.ip}:${builtins.toString port}/v1/status/leader";
            interval = "30s";
            timeout = "10s";
          };
        }];

        services.consul.extraConfigFiles = [
          config.sops.secrets."consul-config".path
        ];

        networking.firewall.allowedTCPPorts = [
          port
          rpcPort
          serfLanPort
          serfWanPort
          grpcTlsPort
          dnsPort
        ];

        networking.firewall.allowedUDPPorts = [
          serfLanPort
          serfWanPort
          dnsPort
        ];

        programs.rust-motd.settings = {
          service_status = {
            Consul = "consul";
          };
        };

        sops.secrets."consul-config" = {
          path = configPath;
          owner = config.systemd.services.consul.serviceConfig.User;
          group = config.systemd.services.consul.serviceConfig.User;
          mode = "0400";
        };
        sops.secrets."consul-ca-public" = {
          key = "openssl-ca-public";
          path = "${certs}/ca.crt";
          owner = config.systemd.services.consul.serviceConfig.User;
          group = config.systemd.services.consul.serviceConfig.User;
          mode = "0644";
        };
        sops.secrets."consul-public" = {
          path = "${certs}/consul.crt";
          owner = config.systemd.services.consul.serviceConfig.User;
          group = config.systemd.services.consul.serviceConfig.User;
          mode = "0644";
        };
        sops.secrets."consul-private" = {
          path = "${certs}/consul.key";
          owner = config.systemd.services.consul.serviceConfig.User;
          group = config.systemd.services.consul.serviceConfig.User;
          mode = "0400";
        };

        rumor.sops = [
          "consul-private"
          "consul-public"
          "consul-config"
        ];

        rumor.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "consul-gossip-key";
              allow_fail = true;
            };
          }
          {
            importer = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "consul-bootstrap-token";
              allow_fail = true;
            };
          }
        ];
        rumor.specification.generations = [
          {
            generator = "text";
            arguments = {
              name = "consul-cert-config";
              renew = true;
              text = ''
                [req]
                distinguished_name = req_distinguished_name
                prompt = no

                [req_distinguished_name]
                CN = Consul
                O = Dot

                [ext]
                basicConstraints = CA:FALSE
                keyUsage = nonRepudiation,digitalSignature,keyEncipherment
                subjectAltName = @alt_names

                [alt_names]
                DNS.1 = consul.service.consul
                DNS.2 = ${config.dot.host.name}.dot
                DNS.3 = localhost
                IP.1 = ${config.dot.host.ip}
                IP.2 = 127.0.0.1
              '';
            };
          }
          {
            generator = "openssl";
            arguments = {
              ca_private = "openssl-ca-private";
              ca_public = "openssl-ca-public";
              serial = "openssl-ca-serial";
              config = "consul-cert-config";
              private = "consul-private";
              public = "consul-public";
              renew = true;
            };
          }
          {
            generator = "key";
            arguments = {
              name = "consul-gossip-key";
            };
          }
          {
            generator = "key";
            arguments = {
              name = "consul-bootstrap-token";
            };
          }
          {
            generator = "moustache";
            arguments = {
              name = "consul-config";
              renew = true;
              variables = {
                CONSUL_GOSSIP_KEY = "consul-gossip-key";
                CONSUL_BOOTSTRAP_TOKEN = "consul-bootstrap-token";
              };
              template = ''
                {
                  "encrypt": "{{CONSUL_GOSSIP_KEY}}",
                  "acl": {
                    "tokens": {
                      "initial_management": "{{CONSUL_BOOTSTRAP_TOKEN}}"
                    }
                  }
                }
              '';
            };
          }
        ];
        rumor.specification.exports = [
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "consul-gossip-key";
            };
          }
          {
            exporter = "vault-file";
            arguments = {
              path = "kv/dot/shared";
              file = "consul-bootstrap-token";
            };
          }
        ];
      })
    ];
  };
}
