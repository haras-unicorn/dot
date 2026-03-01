{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      # Generate test certificates for nebula
      testCerts =
        pkgs.runCommand "nebula-test-certs"
          {
            nativeBuildInputs = [ pkgs.nebula ];
          }
          ''
            mkdir -p $out

            # Generate CA
            nebula-cert ca -name "TestCA" -out-crt $out/ca.crt -out-key $out/ca.key

            # Generate lighthouse certificate (10.69.42.1)
            nebula-cert sign -name "lighthouse" \
              -ip "10.69.42.1/24" \
              -ca-crt $out/ca.crt -ca-key $out/ca.key \
              -out-crt $out/lighthouse.crt -out-key $out/lighthouse.key

            # Generate node1 certificate (10.69.42.2)
            nebula-cert sign -name "node1" \
              -ip "10.69.42.2/24" \
              -ca-crt $out/ca.crt -ca-key $out/ca.key \
              -out-crt $out/node1.crt -out-key $out/node1.key

            # Generate node2 certificate (10.69.42.3)
            nebula-cert sign -name "node2" \
              -ip "10.69.42.3/24" \
              -ca-crt $out/ca.crt -ca-key $out/ca.key \
              -out-crt $out/node2.crt -out-key $out/node2.key
          '';

      # Common nebula options mock (only define what the module doesn't define)
      nebulaOptions = {
        dot.hardware.network.enable = pkgs.lib.mkOption {
          type = pkgs.lib.types.bool;
          default = true;
        };
      };

      # Sops secrets mock submodule
      sopsSecretsSubmodule = pkgs.lib.types.submodule {
        options = {
          path = pkgs.lib.mkOption { type = pkgs.lib.types.str; };
          owner = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "root";
          };
          group = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "root";
          };
          mode = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "0400";
          };
        };
      };

      # Mock chronyd-synced.target
      mockChronydModule =
        { lib, ... }:
        {
          systemd.targets.chronyd-synced = {
            description = "Mock chronyd synced target";
            after = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          };
        };

      underlyingNetworkIp = "192.168.1.10";
    in
    {
      # Test 1: Nebula disabled when network is disabled
      checks.test-critical-nebula-disabled = config.flake.lib.test.mkTest pkgs {
        name = "critical-nebula-disabled";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-nebula
            config.flake.nixosModules.rumor
          ];
          options = pkgs.lib.recursiveUpdate nebulaOptions {
            dot.host.user = pkgs.lib.mkOption {
              type = pkgs.lib.types.str;
              default = "testuser";
            };
            sops.secrets = pkgs.lib.mkOption {
              type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
              default = { };
            };
          };
          config = {
            networking.hostName = "testhost";
            dot.hardware.network.enable = false;
            dot.nebula.ip = "10.69.42.1";
            dot.nebula.subnet.ip = "10.69.42.0";
            dot.nebula.subnet.bits = 24;
            dot.nebula.subnet.mask = "255.255.255.0";
            users.users.testuser = {
              isNormalUser = true;
              home = "/home/testuser";
            };
          };
        };
        script = ''
          start_all()

          # Verify nebula service is not enabled when network is disabled
          machine.fail("systemctl is-enabled nebula@dot.service 2>/dev/null || systemctl status nebula@dot.service")

          # Verify no nebula interface exists
          machine.fail("ip link show nebula-dot 2>/dev/null")

          # Verify config files are not created
          machine.fail("test -f /etc/nebula/config.d/config.yaml")
        '';
      };

      # Test 2: Multi-node nebula mesh with connectivity tests
      checks.test-critical-nebula-mesh = config.flake.lib.test.mkTest pkgs {
        name = "critical-nebula-mesh";
        nodes = {
          lighthouse = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "lighthouse";
              virtualisation.vlans = [ 1 ];

              # Static IP on the underlying network (eth1)
              networking.interfaces.eth1.ipv4.addresses = [
                {
                  address = underlyingNetworkIp;
                  prefixLength = 24;
                }
              ];

              dot.nebula.lighthouse = true;
              dot.nebula.ip = "10.69.42.1";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/lighthouse.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/lighthouse.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Lighthouse configuration
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                lighthouse:
                  am_lighthouse: true
                  serve_dns: false
                  interval: 60
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };

          node1 = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "node1";
              virtualisation.vlans = [ 1 ];

              dot.nebula.lighthouse = false;
              dot.nebula.ip = "10.69.42.2";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/node1.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/node1.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Regular node configuration - uses lighthouse's underlying network IP
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                static_host_map:
                  "10.69.42.1": ["${underlyingNetworkIp}:4242"]
                lighthouse:
                  am_lighthouse: false
                  hosts:
                    - '10.69.42.1'
                  interval: 60
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };

          node2 = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "node2";
              virtualisation.vlans = [ 1 ];

              dot.nebula.lighthouse = false;
              dot.nebula.ip = "10.69.42.3";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/node2.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/node2.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Regular node configuration - uses lighthouse's underlying network IP
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                static_host_map:
                  "10.69.42.1": ["${underlyingNetworkIp}:4242"]
                lighthouse:
                  am_lighthouse: false
                  hosts:
                    - '10.69.42.1'
                  interval: 60
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };
        };

        script = ''
          import time

          # Start all VMs
          start_all()

          # Wait for network to be online
          lighthouse.wait_for_unit("network-online.target")
          node1.wait_for_unit("network-online.target")
          node2.wait_for_unit("network-online.target")

          # Wait for nebula service to start on all nodes
          lighthouse.wait_for_unit("nebula@dot.service")
          node1.wait_for_unit("nebula@dot.service")
          node2.wait_for_unit("nebula@dot.service")

          # Wait for nebula TUN interface to be up
          lighthouse.wait_until_succeeds("ip link show nebula-dot")
          node1.wait_until_succeeds("ip link show nebula-dot")
          node2.wait_until_succeeds("ip link show nebula-dot")

          # Give nebula time to establish mesh connections
          time.sleep(10)

          # Verify config files exist and have correct content
          # Lighthouse config check
          lighthouse.succeed("test -f /etc/nebula/config.d/config.yaml")
          lighthouse.succeed("grep -q 'am_lighthouse: true' /etc/nebula/config.d/config.yaml || grep -q 'port: 4242' /etc/nebula/config.d/config.yaml")

          # Node config checks
          node1.succeed("test -f /etc/nebula/config.d/config.yaml")
          node1.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node1.succeed("grep -q 'port: 0' /etc/nebula/config.d/config.yaml")

          node2.succeed("test -f /etc/nebula/config.d/config.yaml")
          node2.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node2.succeed("grep -q 'port: 0' /etc/nebula/config.d/config.yaml")

          # Verify firewall: lighthouse should have port 4242 open
          lighthouse.succeed("iptables -L -n | grep -q '4242'")

          # Verify firewall: nodes should NOT have port 4242 open
          node1.fail("iptables -L -n | grep -q '4242'")
          node2.fail("iptables -L -n | grep -q '4242'")

          # Verify nebula interface has the correct IP
          lighthouse.succeed("ip addr show nebula-dot | grep -q '10.69.42.1'")
          node1.succeed("ip addr show nebula-dot | grep -q '10.69.42.2'")
          node2.succeed("ip addr show nebula-dot | grep -q '10.69.42.3'")

          # Test connectivity through nebula
          # node1 -> lighthouse
          node1.succeed("ping -c 3 10.69.42.1")

          # node2 -> lighthouse
          node2.succeed("ping -c 3 10.69.42.1")

          # lighthouse -> node1
          lighthouse.succeed("ping -c 3 10.69.42.2")

          # lighthouse -> node2
          lighthouse.succeed("ping -c 3 10.69.42.3")

          # node1 <-> node2 (mesh connectivity)
          node1.succeed("ping -c 3 10.69.42.3")
          node2.succeed("ping -c 3 10.69.42.2")
        '';
      };

      # Test 3: Nebula relay test - nodes on different VLANs that can only communicate through the relay
      checks.test-critical-nebula-relay = config.flake.lib.test.mkTest pkgs {
        name = "critical-nebula-relay";
        nodes = {
          # Relay/Lighthouse - connected to both VLANs
          relay = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "relay";
              # Relay is on both VLANs
              virtualisation.vlans = [
                1
                2
              ];

              networking.interfaces.eth1.ipv4.addresses = [
                {
                  address = "192.168.1.10";
                  prefixLength = 24;
                }
              ];
              networking.interfaces.eth2.ipv4.addresses = [
                {
                  address = "192.168.2.10";
                  prefixLength = 24;
                }
              ];

              dot.nebula.lighthouse = true;
              dot.nebula.ip = "10.69.42.1";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/lighthouse.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/lighthouse.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Relay configuration with am_relay: true
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                lighthouse:
                  am_lighthouse: true
                  serve_dns: false
                  interval: 60
                punchy:
                  punch: true
                relay:
                  am_relay: true
                  use_relays: true
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };

          # Node1 - only on VLAN 1 (can reach relay on 192.168.1.10)
          node1 = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "node1";
              virtualisation.vlans = [ 1 ];

              networking.interfaces.eth1.ipv4.addresses = [
                {
                  address = "192.168.1.20";
                  prefixLength = 24;
                }
              ];

              dot.nebula.lighthouse = false;
              dot.nebula.ip = "10.69.42.2";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/node1.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/node1.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Node configuration with relay support
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                static_host_map:
                  "10.69.42.1": ["192.168.1.10:4242"]
                lighthouse:
                  am_lighthouse: false
                  hosts:
                    - '10.69.42.1'
                  interval: 60
                punchy:
                  punch: true
                relay:
                  am_relay: false
                  use_relays: true
                  relays:
                    - "10.69.42.1"
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };

          # Node2 - only on VLAN 2 (can reach relay on 192.168.2.10)
          node2 = {
            imports = [
              config.flake.nixosModules.critical-nebula
              config.flake.nixosModules.rumor
              mockChronydModule
            ];
            options = pkgs.lib.recursiveUpdate nebulaOptions {
              dot.host.user = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                default = "testuser";
              };
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            };
            config = {
              networking.hostName = "node2";
              virtualisation.vlans = [ 2 ];

              networking.interfaces.eth1.ipv4.addresses = [
                {
                  address = "192.168.2.20";
                  prefixLength = 24;
                }
              ];

              dot.nebula.lighthouse = false;
              dot.nebula.ip = "10.69.42.3";
              dot.nebula.subnet.ip = "10.69.42.0";
              dot.nebula.subnet.bits = 24;
              dot.nebula.subnet.mask = "255.255.255.0";

              # Set up mock sops secrets pointing to test certs
              sops.secrets = {
                "nebula-ca-public" = {
                  path = "${testCerts}/ca.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-public" = {
                  path = "${testCerts}/node2.crt";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0644";
                };
                "nebula-private" = {
                  path = "${testCerts}/node2.key";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
                "nebula-lighthouse" = {
                  path = "/etc/nebula/config.d/lighthouse.yaml";
                  owner = "nebula-dot";
                  group = "nebula-dot";
                  mode = "0400";
                };
              };

              # Node configuration with relay support
              environment.etc."nebula/config.d/lighthouse.yaml".text = ''
                static_host_map:
                  "10.69.42.1": ["192.168.2.10:4242"]
                lighthouse:
                  am_lighthouse: false
                  hosts:
                    - '10.69.42.1'
                  interval: 60
                punchy:
                  punch: true
                relay:
                  am_relay: false
                  use_relays: true
                  relays:
                    - "10.69.42.1"
              '';

              users.users.testuser = {
                isNormalUser = true;
                home = "/home/testuser";
              };

              users.users.nebula-dot = {
                isSystemUser = true;
                group = "nebula-dot";
              };
              users.groups.nebula-dot = { };
            };
          };
        };

        script = ''
          import time

          # Start all VMs
          start_all()

          # Wait for network to be online
          relay.wait_for_unit("network-online.target")
          node1.wait_for_unit("network-online.target")
          node2.wait_for_unit("network-online.target")

          # Wait for nebula service to start on all nodes
          relay.wait_for_unit("nebula@dot.service")
          node1.wait_for_unit("nebula@dot.service")
          node2.wait_for_unit("nebula@dot.service")

          # Wait for nebula TUN interface to be up
          relay.wait_until_succeeds("ip link show nebula-dot")
          node1.wait_until_succeeds("ip link show nebula-dot")
          node2.wait_until_succeeds("ip link show nebula-dot")

          # Give nebula time to establish connections via relay
          # This takes longer because nodes need to discover they can't reach each other directly
          time.sleep(15)

          # Verify config files exist and have relay configuration
          # Relay config check
          relay.succeed("test -f /etc/nebula/config.d/config.yaml")
          relay.succeed("grep -q 'am_relay: true' /etc/nebula/config.d/lighthouse.yaml")

          # Node config checks
          node1.succeed("test -f /etc/nebula/config.d/config.yaml")
          node1.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node1.succeed("grep -q 'use_relays: true' /etc/nebula/config.d/lighthouse.yaml")
          node1.succeed("grep -q '10.69.42.1' /etc/nebula/config.d/lighthouse.yaml")

          node2.succeed("test -f /etc/nebula/config.d/config.yaml")
          node2.succeed("test -f /etc/nebula/config.d/lighthouse.yaml")
          node2.succeed("grep -q 'use_relays: true' /etc/nebula/config.d/lighthouse.yaml")
          node2.succeed("grep -q '10.69.42.1' /etc/nebula/config.d/lighthouse.yaml")

          # Verify firewall: relay should have port 4242 open
          relay.succeed("iptables -L -n | grep -q '4242'")

          # Verify firewall: nodes should NOT have port 4242 open
          node1.fail("iptables -L -n | grep -q '4242'")
          node2.fail("iptables -L -n | grep -q '4242'")

          # Verify nebula interface has the correct IP
          relay.succeed("ip addr show nebula-dot | grep -q '10.69.42.1'")
          node1.succeed("ip addr show nebula-dot | grep -q '10.69.42.2'")
          node2.succeed("ip addr show nebula-dot | grep -q '10.69.42.3'")

          # Test connectivity through underlying network
          # Each node can reach the relay
          node1.succeed("ping -c 3 192.168.1.10")
          node2.succeed("ping -c 3 192.168.2.10")
          relay.succeed("ping -c 3 192.168.1.20")
          relay.succeed("ping -c 3 192.168.2.20")

          # Test connectivity through relay
          # Each node can reach the relay
          node1.succeed("ping -c 3 10.69.42.1")
          node2.succeed("ping -c 3 10.69.42.1")
          relay.succeed("ping -c 3 10.69.42.2")
          relay.succeed("ping -c 3 10.69.42.3")

          # THE KEY TEST: nodes can reach each other THROUGH THE RELAY
          # even though they are on different VLANs and can't communicate directly
          node1.succeed("ping -c 3 10.69.42.3")
          node2.succeed("ping -c 3 10.69.42.2")

          # Verify relay is actually being used by checking that nodes can't reach each other directly
          # Node1 should not be able to ping node2's underlying IP
          node1.fail("ping -c 1 192.168.2.10 || ping -c 1 192.168.2.20")
        '';
      };
    };
}
