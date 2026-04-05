{ self, ... }:

{
  dot.domains.topLevel = "dot";
  dot.domains.service = "service.dot";
  dot.domains.node = "node.dot";

  flake.homeModules.critical-consul =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      hasMonitor = config.dot.hardware.monitor.enable;
    in
    lib.mkIf hasNetwork {
      home.packages = [
        pkgs.consul
      ];

      xdg.desktopEntries = lib.mkIf hasMonitor {
        consul = {
          name = "Consul";
          exec =
            "${config.dot.browser.package}/bin/${config.dot.browser.bin}"
            + " --new-window consul-ui.${config.dot.domains.service}";
          terminal = false;
        };
      };
    };

  flake.nixosModules.critical-consul =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
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
      hosts = builtins.map (x: x.ip) (
        builtins.filter (
          x:
          if lib.hasAttrByPath [ "system" "dot" "consul" "enable" ] x then
            x.system.dot.consul.enable
          else
            false
        ) config.dot.host.hosts
      );
      retryJoinHosts = builtins.filter (x: x != config.dot.host.ip) hosts;
    in
    {
      options.dot = {
        consul = {
          enable = lib.mkEnableOption "Consul";
        };
      };

      config = lib.mkMerge [
        (lib.mkIf (hasNetwork && !config.dot.consul.enable) {
          networking.networkmanager.dispatcherScripts = [
            {
              source = pkgs.writeText "disable-dnssec-${config.dot.host.interface}" ''
                if [ "$1" = "${config.dot.host.interface}" ] && [ "$2" = "up" ]; then
                  ${pkgs.systemd}/bin/resolvectl dnssec $1 off
                  ${pkgs.systemd}/bin/resolvectl dnsovertls $1 off
                  ${pkgs.systemd}/bin/resolvectl domain $1 ~${config.dot.domains.topLevel}
                  ${pkgs.systemd}/bin/resolvectl dns $1 ${builtins.concatStringsSep " " hosts}
                fi
              '';
              type = "basic";
            }
          ];

        })
        (lib.mkIf (hasNetwork && config.dot.consul.enable) {
          networking.networkmanager.ensureProfiles.profiles.${config.dot.host.interface} = {
            connection = {
              id = config.dot.host.interface;
            };
            ipv4 = {
              dns = "127.0.0.1";
              dns-search = "~${config.dot.domains.topLevel};";
            };
          };

          systemd.services.consul.wantedBy = [
            "dot-network-online.target"
            "dot-time-synchronized.target"
          ];
          systemd.services.consul.after = [
            "dot-network-online.target"
            "dot-time-synchronized.target"
          ];
          systemd.services.consul.requires = [
            "dot-network-online.target"
            "dot-time-synchronized.target"
          ];
          systemd.services.consul.serviceConfig = {
            Restart = lib.mkForce "always";
          };

          services.consul.enable = true;
          services.consul.webUi = true;
          services.consul.dropPrivileges = false;

          services.consul.extraConfig = {
            domain = config.dot.domains.topLevel;
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

            services = builtins.map (service: {
              inherit (service) name port address;
              tags = [
                "dot.enable=true"
              ]
              ++ (lib.optional service.tls "dot.http.services.${service.name}.loadbalancer.server.scheme=https");
              check =
                let
                  protocol = builtins.head (
                    builtins.filter (protocol: lib.hasPrefix protocol service.health) self.lib.services.protocols
                  );
                  key = if protocol == "tcp://" then "tcp" else "http";
                in
                {
                  ${key} =
                    protocol
                    + service.address
                    + ":"
                    + builtins.toString service.port
                    + lib.removePrefix protocol service.health;
                  timeout = "30s";
                  interval = "10s";
                };
            }) config.dot.services;
          };

          dot.services = [
            {
              name = "consul-ui";
              port = port;
              tls = true;
              health = "https:///v1/status/leader";
            }
          ];

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

          cryl.sops.keys = [
            "consul-private"
            "consul-public"
            "consul-config"
          ];

          cryl.specification.imports = [
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "consul-gossip-key";
                allow_fail = true;
              };
            }
            {
              importer = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "consul-bootstrap-token";
                allow_fail = true;
              };
            }
          ];
          cryl.specification.generations = [
            {
              generator = "tls-leaf";
              arguments = {
                common_name = "dot";
                organization = "Dot";
                sans = [
                  "consul.${config.dot.domains.service}"
                  "consul-ui.${config.dot.domains.service}"
                  "localhost"
                  "${config.dot.host.ip}"
                  "127.0.0.1"
                ];
                config = "consul-cert-config";
                request_config = "consul-cert-request-config";
                private = "consul-private";
                request = "consul-cert-request";
                ca_private = "openssl-ca-private";
                ca_public = "openssl-ca-public";
                serial = "openssl-ca-serial";
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
          cryl.specification.exports = [
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "consul-gossip-key";
              };
            }
            {
              exporter = "vault-file";
              arguments = {
                path = self.lib.vault.shared;
                file = "consul-bootstrap-token";
              };
            }
          ];
        })
      ];
    };
}
