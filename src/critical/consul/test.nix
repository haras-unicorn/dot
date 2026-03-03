{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      # Generate test certificates for consul using openssl
      testCerts =
        pkgs.runCommand "consul-test-certs"
          {
            nativeBuildInputs = [ pkgs.openssl ];
          }
          ''
            mkdir -p $out

            # Generate CA key and certificate
            openssl genrsa -out $out/ca.key 2048
            openssl req -new -x509 -days 365 -key $out/ca.key \
              -subj "/C=US/ST=Test/L=Test/O=Dot/CN=Consul Test CA" \
              -out $out/ca.crt

            # Generate consul server key and CSR
            openssl genrsa -out $out/consul.key 2048
            openssl req -new -key $out/consul.key \
              -subj "/C=US/ST=Test/L=Test/O=Dot/CN=testhost.dot" \
              -out $out/consul.csr

            # Create extensions file for SAN
            cat > $out/extensions.cnf << EOF
            basicConstraints=CA:FALSE
            keyUsage = digitalSignature, keyEncipherment
            extendedKeyUsage = serverAuth, clientAuth
            subjectAltName = @alt_names

            [alt_names]
            DNS.1 = consul.service.consul
            DNS.2 = testhost.dot
            DNS.3 = localhost
            IP.1 = 192.168.1.10
            IP.2 = 192.168.1.11
            IP.3 = 192.168.1.12
            IP.4 = 127.0.0.1
            EOF

            # Sign the consul certificate with the CA
            openssl x509 -req -days 365 -in $out/consul.csr \
              -CA $out/ca.crt -CAkey $out/ca.key -CAcreateserial \
              -extfile $out/extensions.cnf \
              -out $out/consul.crt

            # Set permissions in the output
            chmod 644 $out/ca.crt
            chmod 644 $out/consul.crt
            chmod 400 $out/consul.key
          '';
    in
    {
      # Test 1: Consul disabled - no service should be configured
      checks.test-critical-consul-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-consul-disabled";
        module = config.flake.nixosModules.critical-consul;
        serviceName = "consul.service";
        configPath = "/etc/consul";
      };

      # Test 2: Consul enabled - full server setup
      checks.test-critical-consul-enabled = config.flake.lib.test.mkTest pkgs {
        name = "critical-consul-enabled";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-consul
            config.flake.nixosModules.rumor
            config.flake.lib.test.mockNebulaChronydTargetsModule
            config.flake.lib.test.commonDotOptionsModule
            config.flake.lib.test.sopsSecretsModule
          ];

          networking.hostName = "testhost";

          # Configure eth1 with the IP address consul expects
          networking.interfaces.eth1.ipv4.addresses = [
            {
              address = "192.168.1.10";
              prefixLength = 24;
            }
          ];

          dot.consul.enable = true;

          # Override consul config to set bootstrap_expect for single-node cluster
          services.consul.extraConfig.bootstrap_expect = pkgs.lib.mkForce 1;

          # Mock sops secrets for consul - use mkForce to override module defaults
          # Point to /etc/consul/certs/ where we'll place the certs
          sops.secrets = {
            "consul-config" = pkgs.lib.mkForce {
              path = "/etc/consul/config.json";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
            "consul-ca-public" = pkgs.lib.mkForce {
              key = "openssl-ca-public";
              path = "/etc/consul/certs/ca.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-public" = pkgs.lib.mkForce {
              path = "/etc/consul/certs/consul.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-private" = pkgs.lib.mkForce {
              path = "/etc/consul/certs/consul.key";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
          };

          # Place certificates in /etc/consul/certs/
          environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
          environment.etc."consul/certs/consul.crt".source = "${testCerts}/consul.crt";
          environment.etc."consul/certs/consul.key".source = "${testCerts}/consul.key";

          # Create consul config file content with gossip encryption key
          environment.etc."consul/config.json".text = ''
            {
              "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
              "acl": {
                "enabled": false
              }
            }
          '';

          # Ensure consul user exists
          users.users.consul = {
            isSystemUser = true;
            group = "consul";
          };
          users.groups.consul = { };

          # Add curl for API testing
          environment.systemPackages = [ pkgs.curl ];
        };
        script = ''
          import time

          start_all()

          # Wait for consul service to be ready
          machine.wait_for_unit("consul.service")

          # Give consul time to initialize and elect a leader
          time.sleep(10)

          # Verify consul binary is available
          machine.succeed("which consul")

          # Verify consul service is enabled
          machine.succeed("systemctl is-enabled consul.service")

          # Verify consul config directory exists
          machine.succeed("test -d /etc/consul")

          # Verify certificate directory exists
          machine.succeed("test -d /etc/consul/certs")

          # Wait for consul API to be ready and return a leader (non-empty response)
          machine.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.10:8500/v1/status/leader)\"")

          # Verify consul is responding to HTTPS API requests (with -k to skip cert verification)
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/status/leader | grep -q '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:[0-9]\\+'")

          # Verify consul reports itself as a server
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/agent/self | grep -q 'testhost'")

          # Verify datacenter is set correctly
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/datacenters | grep -q 'dot'")

          # Verify firewall ports are open (TCP)
          machine.succeed("iptables -L -n | grep -q '8500'")
          machine.succeed("iptables -L -n | grep -q '8300'")
          machine.succeed("iptables -L -n | grep -q '8301'")
          machine.succeed("iptables -L -n | grep -q '8302'")
          machine.succeed("iptables -L -n | grep -q '8503'")

          # Verify NetworkManager dispatcher script is NOT present when consul is enabled
          machine.fail("grep -r 'disable-dnssec-nebula' /etc/NetworkManager/dispatcher.d/ 2>/dev/null")
        '';
      };

      # Test 3: Consul with service registration
      checks.test-critical-consul-services = config.flake.lib.test.mkTest pkgs {
        name = "critical-consul-services";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-consul
            config.flake.nixosModules.rumor
            config.flake.lib.test.mockNebulaChronydTargetsModule
            config.flake.lib.test.commonDotOptionsModule
            config.flake.lib.test.sopsSecretsModule
          ];

          networking.hostName = "testhost";

          # Configure eth1 with the IP address consul expects
          networking.interfaces.eth1.ipv4.addresses = [
            {
              address = "192.168.1.10";
              prefixLength = 24;
            }
          ];

          dot.consul.enable = true;

          # Override consul config to set bootstrap_expect for single-node cluster
          services.consul.extraConfig.bootstrap_expect = pkgs.lib.mkForce 1;

          dot.consul.services = [
            {
              name = "test-service";
              port = 8080;
              address = "192.168.1.10";
              tags = [
                "test"
                "dot"
              ];
              check = {
                http = "http://192.168.1.10:8080/health";
                interval = "10s";
                timeout = "5s";
              };
            }
          ];

          # Mock sops secrets - use mkForce to override module defaults
          sops.secrets = {
            "consul-config" = pkgs.lib.mkForce {
              path = "/etc/consul/config.json";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
            "consul-ca-public" = pkgs.lib.mkForce {
              key = "openssl-ca-public";
              path = "/etc/consul/certs/ca.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-public" = pkgs.lib.mkForce {
              path = "/etc/consul/certs/consul.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-private" = pkgs.lib.mkForce {
              path = "/etc/consul/certs/consul.key";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
          };

          # Place certificates in /etc/consul/certs/
          environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
          environment.etc."consul/certs/consul.crt".source = "${testCerts}/consul.crt";
          environment.etc."consul/certs/consul.key".source = "${testCerts}/consul.key";

          # Create consul config file content with gossip encryption key
          environment.etc."consul/config.json".text = ''
            {
              "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
              "acl": {
                "enabled": false
              }
            }
          '';

          users.users.consul = {
            isSystemUser = true;
            group = "consul";
          };
          users.groups.consul = { };

          # Add curl for API testing
          environment.systemPackages = [ pkgs.curl ];
        };
        script = ''
          import time

          start_all()

          # Wait for consul service to be ready
          machine.wait_for_unit("consul.service")

          # Give consul time to initialize and elect a leader
          time.sleep(10)

          # Verify consul binary is available
          machine.succeed("which consul")

          # Verify consul service is enabled
          machine.succeed("systemctl is-enabled consul.service")

          # Wait for consul API to be ready and return a leader (non-empty response)
          machine.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.10:8500/v1/status/leader)\"")

          # Verify consul is responding to HTTPS API requests
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/status/leader | grep -q '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:[0-9]\\+'")

          # Verify test-service is registered in catalog
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/test-service | grep -q 'test-service'")

          # Verify test-service has correct tags
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/test-service | grep -q 'test'")
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/test-service | grep -q 'dot'")

          # Verify consul-ui service is registered (auto-added by module)
          machine.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/consul-ui | grep -q 'consul-ui'")
        '';
      };

      # Test 4: Multi-node consul cluster
      checks.test-critical-consul-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-consul-cluster";
        nodes = {
          node1 = {
            imports = [
              config.flake.nixosModules.critical-consul
              config.flake.nixosModules.rumor
              config.flake.lib.test.mockNebulaChronydTargetsModule
              config.flake.lib.test.commonDotOptionsModule
              config.flake.lib.test.sopsSecretsModule
            ];

            dot.host.ip = "192.168.1.10";

            dot.host.hosts = [
              {
                ip = "192.168.1.10";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.11";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.12";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
            ];

            networking.hostName = "node1";
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.1.10";
                prefixLength = 24;
              }
            ];
            dot.host.name = "node1";
            dot.consul.enable = true;
            sops.secrets = {
              "consul-config" = pkgs.lib.mkForce { path = "/etc/consul/config.json"; };
              "consul-ca-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/ca.crt"; };
              "consul-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.crt"; };
              "consul-private" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.key"; };
            };
            # Place certificates in /etc/consul/certs/
            environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
            environment.etc."consul/certs/consul.crt".source = "${testCerts}/consul.crt";
            environment.etc."consul/certs/consul.key".source = "${testCerts}/consul.key";
            # Create consul config file content with gossip encryption key
            environment.etc."consul/config.json".text = ''
              {
                "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
                "acl": {
                  "enabled": false
                }
              }
            '';
            users.users.consul = {
              isSystemUser = true;
              group = "consul";
            };
            users.groups.consul = { };
            # Add curl for API testing
            environment.systemPackages = [ pkgs.curl ];
          };
          node2 = {
            imports = [
              config.flake.nixosModules.critical-consul
              config.flake.nixosModules.rumor
              config.flake.lib.test.mockNebulaChronydTargetsModule
              config.flake.lib.test.commonDotOptionsModule
              config.flake.lib.test.sopsSecretsModule
            ];

            dot.host.ip = "192.168.1.11";

            dot.host.hosts = [
              {
                ip = "192.168.1.10";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.11";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.12";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
            ];

            networking.hostName = "node2";
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.1.11";
                prefixLength = 24;
              }
            ];
            dot.host.name = "node2";
            dot.consul.enable = true;
            sops.secrets = {
              "consul-config" = pkgs.lib.mkForce { path = "/etc/consul/config.json"; };
              "consul-ca-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/ca.crt"; };
              "consul-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.crt"; };
              "consul-private" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.key"; };
            };
            # Place certificates in /etc/consul/certs/
            environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
            environment.etc."consul/certs/consul.crt".source = "${testCerts}/consul.crt";
            environment.etc."consul/certs/consul.key".source = "${testCerts}/consul.key";
            # Create consul config file content with gossip encryption key
            environment.etc."consul/config.json".text = ''
              {
                "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
                "acl": {
                  "enabled": false
                }
              }
            '';
            users.users.consul = {
              isSystemUser = true;
              group = "consul";
            };
            users.groups.consul = { };
            # Add curl for API testing
            environment.systemPackages = [ pkgs.curl ];
          };
          node3 = {
            imports = [
              config.flake.nixosModules.critical-consul
              config.flake.nixosModules.rumor
              config.flake.lib.test.mockNebulaChronydTargetsModule
              config.flake.lib.test.commonDotOptionsModule
              config.flake.lib.test.sopsSecretsModule
            ];

            dot.host.ip = "192.168.1.12";
            dot.host.hosts = [
              {
                ip = "192.168.1.10";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.11";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
              {
                ip = "192.168.1.12";
                system = {
                  dot = {
                    consul = {
                      enable = true;
                    };
                  };
                };
              }
            ];

            networking.hostName = "node3";
            networking.interfaces.eth1.ipv4.addresses = [
              {
                address = "192.168.1.12";
                prefixLength = 24;
              }
            ];
            dot.host.name = "node3";
            dot.consul.enable = true;
            sops.secrets = {
              "consul-config" = pkgs.lib.mkForce { path = "/etc/consul/config.json"; };
              "consul-ca-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/ca.crt"; };
              "consul-public" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.crt"; };
              "consul-private" = pkgs.lib.mkForce { path = "/etc/consul/certs/consul.key"; };
            };
            # Place certificates in /etc/consul/certs/
            environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
            environment.etc."consul/certs/consul.crt".source = "${testCerts}/consul.crt";
            environment.etc."consul/certs/consul.key".source = "${testCerts}/consul.key";
            # Create consul config file content with gossip encryption key
            environment.etc."consul/config.json".text = ''
              {
                "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
                "acl": {
                  "enabled": false
                }
              }
            '';
            users.users.consul = {
              isSystemUser = true;
              group = "consul";
            };
            users.groups.consul = { };
            # Add curl for API testing
            environment.systemPackages = [ pkgs.curl ];
          };
        };
        script = ''
          import time

          start_all()

          # Wait for network to be online on all nodes
          node1.wait_for_unit("network-online.target")
          node2.wait_for_unit("network-online.target")
          node3.wait_for_unit("network-online.target")

          # Wait for consul services to start on all nodes
          node1.wait_for_unit("consul.service")
          node2.wait_for_unit("consul.service")
          node3.wait_for_unit("consul.service")

          # Give consul time to form the cluster and elect a leader
          # Cluster formation can take 30+ seconds with 3 nodes
          time.sleep(30)

          # Verify consul service is enabled on all nodes
          node1.succeed("systemctl is-enabled consul.service")
          node2.succeed("systemctl is-enabled consul.service")
          node3.succeed("systemctl is-enabled consul.service")

          # Verify consul binary is available on all nodes
          node1.succeed("which consul")
          node2.succeed("which consul")
          node3.succeed("which consul")

          # Verify all servers have unique node names (using dot.host.name which is set per-node)
          node1.succeed("grep 'node1' /etc/consul.json")
          node2.succeed("grep 'node2' /etc/consul.json")
          node3.succeed("grep 'node3' /etc/consul.json")

          # Verify retry_join contains other hosts (not itself)
          node1.succeed("grep -q '192.168.1.11' /etc/consul.json")
          node1.succeed("grep -q '192.168.1.12' /etc/consul.json")
          node2.succeed("grep -q '192.168.1.10' /etc/consul.json")
          node2.succeed("grep -q '192.168.1.12' /etc/consul.json")
          node3.succeed("grep -q '192.168.1.10' /etc/consul.json")
          node3.succeed("grep -q '192.168.1.11' /etc/consul.json")

          # Verify firewall ports are open on all nodes
          node1.succeed("iptables -L -n | grep -q '8500'")
          node1.succeed("iptables -L -n | grep -q '8300'")
          node1.succeed("iptables -L -n | grep -q '8301'")
          node1.succeed("iptables -L -n | grep -q '8302'")
          node2.succeed("iptables -L -n | grep -q '8500'")
          node2.succeed("iptables -L -n | grep -q '8300'")
          node2.succeed("iptables -L -n | grep -q '8301'")
          node2.succeed("iptables -L -n | grep -q '8302'")
          node3.succeed("iptables -L -n | grep -q '8500'")
          node3.succeed("iptables -L -n | grep -q '8300'")
          node3.succeed("iptables -L -n | grep -q '8301'")
          node3.succeed("iptables -L -n | grep -q '8302'")

          # Wait for consul API to be ready and return a leader (non-empty response)
          node1.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.10:8500/v1/status/leader)\"")
          node2.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.11:8500/v1/status/leader)\"")
          node3.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.12:8500/v1/status/leader)\"")

          # Verify all nodes respond to HTTPS API requests with valid leader
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/status/leader | grep -q '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:[0-9]\\+'")
          node2.succeed("curl -sk https://192.168.1.11:8500/v1/status/leader | grep -q '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:[0-9]\\+'")
          node3.succeed("curl -sk https://192.168.1.12:8500/v1/status/leader | grep -q '[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+\\.[0-9]\\+:[0-9]\\+'")

          # Give the cluster a bit more time to fully converge
          time.sleep(5)

          # Verify all nodes can see each other in the cluster
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/agent/members | grep -q 'node2'")
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/agent/members | grep -q 'node3'")
          node2.succeed("curl -sk https://192.168.1.11:8500/v1/agent/members | grep -q 'node1'")
          node2.succeed("curl -sk https://192.168.1.11:8500/v1/agent/members | grep -q 'node3'")
          node3.succeed("curl -sk https://192.168.1.12:8500/v1/agent/members | grep -q 'node1'")
          node3.succeed("curl -sk https://192.168.1.12:8500/v1/agent/members | grep -q 'node2'")

          # Verify cluster has elected a leader by checking the leader is not empty
          leader_output = node1.succeed("curl -sk https://192.168.1.10:8500/v1/status/leader")
          assert leader_output.strip() != '""', "Cluster should have elected a leader"
          assert "8300" in leader_output, "Leader should be listening on port 8300"
        '';
      };
    };
}
