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

      # Underlying network configuration - all nodes on VLAN 1
      # Lighthouse has static IP 192.168.1.1, others use DHCP
      underlyingNetworkIp = "192.168.1.1";
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
    };
}
