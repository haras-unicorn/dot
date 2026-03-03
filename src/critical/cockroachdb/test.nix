{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      # Generate test certificates for cockroachdb using cockroach cert command
      testCerts =
        pkgs.runCommand "cockroachdb-test-certs"
          {
            nativeBuildInputs = [ pkgs.cockroachdb ];
          }
          ''
            mkdir -p $out

            # Create CA
            cockroach cert create-ca \
              --certs-dir=$out \
              --ca-key=$out/ca.key

            # Create node certificate for all nodes in the cluster
            # Include all node IPs and localhost
            cockroach cert create-node \
              localhost \
              127.0.0.1 \
              192.168.1.10 \
              192.168.1.11 \
              192.168.1.12 \
              node1 \
              node2 \
              node3 \
              --certs-dir=$out \
              --ca-key=$out/ca.key

            # Create client certificate for root
            cockroach cert create-client root \
              --certs-dir=$out \
              --ca-key=$out/ca.key

            # Set permissions
            chmod 644 $out/ca.crt
            chmod 644 $out/node.crt
            chmod 400 $out/node.key
            chmod 644 $out/client.root.crt
            chmod 400 $out/client.root.key
          '';

      # Common node configuration
      commonNodeConfig = nodeIp: nodeName: {
        imports = [
          config.flake.nixosModules.critical-cockroachdb
          config.flake.nixosModules.critical-consul
          config.flake.nixosModules.rumor
          config.flake.lib.test.mockNebulaChronydTargetsModule
          config.flake.lib.test.commonDotOptionsModule
          config.flake.lib.test.sopsSecretsModule
        ];

        dot.host.ip = nodeIp;
        dot.host.hosts = [
          {
            ip = "192.168.1.10";
            system = {
              dot = {
                cockroachdb = {
                  enable = true;
                };
              };
            };
          }
          {
            ip = "192.168.1.11";
            system = {
              dot = {
                cockroachdb = {
                  enable = true;
                };
              };
            };
          }
          {
            ip = "192.168.1.12";
            system = {
              dot = {
                cockroachdb = {
                  enable = true;
                };
              };
            };
          }
        ];

        networking.hostName = nodeName;

        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = nodeIp;
            prefixLength = 24;
          }
        ];

        dot.host.name = nodeName;
        dot.cockroachdb.enable = true;

        # Set up certificates using activation script to ensure proper permissions
        system.activationScripts.cockroachdb-certs = {
          text = ''
            mkdir -p /var/lib/cockroachdb/.certs
            cp ${testCerts}/ca.crt /var/lib/cockroachdb/.certs/
            cp ${testCerts}/node.crt /var/lib/cockroachdb/.certs/
            cp ${testCerts}/node.key /var/lib/cockroachdb/.certs/
            cp ${testCerts}/client.root.crt /var/lib/cockroachdb/.certs/
            cp ${testCerts}/client.root.key /var/lib/cockroachdb/.certs/
            chown -R cockroachdb:cockroachdb /var/lib/cockroachdb/.certs
            chmod 644 /var/lib/cockroachdb/.certs/ca.crt
            chmod 644 /var/lib/cockroachdb/.certs/node.crt
            chmod 600 /var/lib/cockroachdb/.certs/node.key
            chmod 644 /var/lib/cockroachdb/.certs/client.root.crt
            chmod 600 /var/lib/cockroachdb/.certs/client.root.key
          '';
          deps = [
            "users"
            "groups"
          ];
        };

        # Mock sops secrets required by the module
        sops.secrets = {
          "cockroach-ca-public" = {
            path = "/var/lib/cockroachdb/.certs/ca.crt";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0644";
          };
          "cockroach-public" = {
            path = "/var/lib/cockroachdb/.certs/node.crt";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0644";
          };
          "cockroach-private" = {
            path = "/var/lib/cockroachdb/.certs/node.key";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0400";
          };
          "cockroach-root-public" = {
            path = "/var/lib/cockroachdb/.certs/client.root.crt";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0644";
          };
          "cockroach-root-private" = {
            path = "/var/lib/cockroachdb/.certs/client.root.key";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0400";
          };
          "cockroach-init" = {
            path = "/etc/cockroachdb/init.sql";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0400";
          };
        };

        environment.etc."cockroachdb/init.sql".text = ''
          CREATE DATABASE IF NOT EXISTS testdb;
        '';

        users.users.cockroachdb = {
          isSystemUser = true;
          group = "cockroachdb";
          home = "/var/lib/cockroachdb";
        };
        users.groups.cockroachdb = { };

        environment.systemPackages = [
          pkgs.curl
          pkgs.cockroachdb
          pkgs.postgresql
        ];
      };
    in
    {
      # Test 1: CockroachDB disabled - no service should be configured
      checks.test-critical-cockroachdb-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-cockroachdb-disabled";
        module = {
          imports = [
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.critical-consul
            config.flake.lib.test.mockNebulaChronydTargetsModule
          ];
        };
        serviceName = "cockroachdb.service";
        configPath = "/etc/cockroachdb";
      };

      # Test 2: Multi-node cockroachdb cluster with secure mode
      checks.test-critical-cockroachdb-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-cluster";
        nodes = {
          node1 = commonNodeConfig "192.168.1.10" "node1";
          node2 = commonNodeConfig "192.168.1.11" "node2";
          node3 = commonNodeConfig "192.168.1.12" "node3";
        };
        script = ''
          start_all()

          # Verify cockroachdb service is enabled on all nodes
          node1.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)

          # Verify cockroachdb binary is available on all nodes
          node1.succeed("which cockroach")
          node2.succeed("which cockroach")
          node3.succeed("which cockroach")

          # Verify certificates exist on all nodes with correct ownership
          node1.succeed("test -f /var/lib/cockroachdb/.certs/ca.crt")
          node1.succeed("test -f /var/lib/cockroachdb/.certs/node.crt")
          node1.succeed("test -f /var/lib/cockroachdb/.certs/node.key")
          node1.succeed("stat -c '%U' /var/lib/cockroachdb/.certs/node.key | grep -q cockroachdb")
          node2.succeed("test -f /var/lib/cockroachdb/.certs/ca.crt")
          node2.succeed("test -f /var/lib/cockroachdb/.certs/node.crt")
          node2.succeed("test -f /var/lib/cockroachdb/.certs/node.key")
          node2.succeed("stat -c '%U' /var/lib/cockroachdb/.certs/node.key | grep -q cockroachdb")
          node3.succeed("test -f /var/lib/cockroachdb/.certs/ca.crt")
          node3.succeed("test -f /var/lib/cockroachdb/.certs/node.crt")
          node3.succeed("test -f /var/lib/cockroachdb/.certs/node.key")
          node3.succeed("stat -c '%U' /var/lib/cockroachdb/.certs/node.key | grep -q cockroachdb")

          # Wait for cockroachdb HTTP API to be ready on all nodes with timeout
          # Just check that the endpoint responds with HTTP 200, content may vary
          node1.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.10:8080/health", timeout=30)
          node2.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.11:8080/health", timeout=30)
          node3.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.12:8080/health", timeout=30)

          # Verify SQL is accessible on all nodes using certificates
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.12 --execute='SELECT 1'")

          # Verify firewall ports are open on all nodes
          node1.succeed("iptables -L -n | grep -q '26257'")
          node1.succeed("iptables -L -n | grep -q '8080'")
          node2.succeed("iptables -L -n | grep -q '26257'")
          node2.succeed("iptables -L -n | grep -q '8080'")
          node3.succeed("iptables -L -n | grep -q '26257'")
          node3.succeed("iptables -L -n | grep -q '8080'")

          # Test data replication - create table on node1, verify on others
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'")
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute=\"INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')\"")

          # Verify data is replicated to other nodes
          node2.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.11 --execute='SELECT message FROM testdb.replication_test WHERE id=1' | grep -q 'hello from cluster'")
          node3.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.12 --execute='SELECT message FROM testdb.replication_test WHERE id=1' | grep -q 'hello from cluster'")

          # Verify cluster membership - check node count (with retries)
          node1.wait_until_succeeds("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT COUNT(*) FROM crdb_internal.gossip_nodes' 2>/dev/null | grep -q '3'")
        '';
      };
    };
}
