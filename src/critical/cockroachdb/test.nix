{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      certsDir = "/var/lib/cockroachdb/.certs";

      nodes = [
        {
          ip = "192.168.1.10";
          name = "node1";
        }
        {
          ip = "192.168.1.11";
          name = "node2";
        }
        {
          ip = "192.168.1.12";
          name = "node3";
        }
      ];

      commonNodeConfig =
        { ip, name, ... }:
        { lib, ... }:
        {
          imports = [ config.flake.lib.test.commonCockroachdbModule ];

          dot.host.name = name;
          dot.host.ip = ip;
          dot.host.hosts = builtins.map (
            { ip, ... }:
            {
              inherit ip;
              system.dot.cockroachdb.enable = true;
            }
          ) nodes;
          networking.hostName = name;
          networking.interfaces.eth1.ipv4.addresses = [
            {
              address = ip;
              prefixLength = 24;
            }
          ];

          services.cockroachdb.certsDir = lib.mkForce certsDir;
          dot.cockroachdb.enable = true;
          dot.test.cockroachdb.certs = config.flake.lib.test.mkCockroachdbCerts pkgs {
            inherit nodes;
            clients = [ ];
          };
          dot.test.cockroachdb.init = ''
            CREATE DATABASE IF NOT EXISTS testdb;
          '';

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
            config.flake.nixosModules.critical-cockroachdb-nixpkgs
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
        nodes = builtins.mapAttrs (_: commonNodeConfig) (
          builtins.listToAttrs (
            builtins.map (node: {
              name = node.name;
              value = node;
            }) nodes
          )
        );
        script = ''
          start_all()

          # Verify cockroachdb service is enabled on all nodes
          node1.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)

          # Wait for cockroachdb to be active
          node1.wait_for_unit("cockroachdb.service", timeout=60)
          node2.wait_for_unit("cockroachdb.service", timeout=60)
          node3.wait_for_unit("cockroachdb.service", timeout=60)

          # Wait for cockroachdb-init to complete (check target is reached)
          node1.wait_for_unit("cockroachdb-init.target", timeout=60)
          node2.wait_for_unit("cockroachdb-init.target", timeout=60)
          node3.wait_for_unit("cockroachdb-init.target", timeout=60)

          # Verify cockroachdb binary is available on all nodes
          node1.succeed("which cockroach")
          node2.succeed("which cockroach")
          node3.succeed("which cockroach")

          # Verify certificates exist on all nodes with correct ownership
          node1.succeed("test -f ${certsDir}/ca.crt")
          node1.succeed("test -f ${certsDir}/node.crt")
          node1.succeed("test -f ${certsDir}/node.key")
          node1.succeed("stat -c '%U' ${certsDir}/node.key | grep -q cockroachdb")
          node2.succeed("test -f ${certsDir}/ca.crt")
          node2.succeed("test -f ${certsDir}/node.crt")
          node2.succeed("test -f ${certsDir}/node.key")
          node2.succeed("stat -c '%U' ${certsDir}/node.key | grep -q cockroachdb")
          node3.succeed("test -f ${certsDir}/ca.crt")
          node3.succeed("test -f ${certsDir}/node.crt")
          node3.succeed("test -f ${certsDir}/node.key")
          node3.succeed("stat -c '%U' ${certsDir}/node.key | grep -q cockroachdb")

          # Wait for cockroachdb HTTP API to be ready on all nodes with timeout
          # Just check that the endpoint responds with HTTP 200, content may vary
          node1.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.10:8080/health", timeout=30)
          node2.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.11:8080/health", timeout=30)
          node3.wait_until_succeeds("curl -k -f --max-time 5 https://192.168.1.12:8080/health", timeout=30)

          # Verify SQL is accessible on all nodes using certificates
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.12 --execute='SELECT 1'")

          # Verify firewall ports are open on all nodes
          node1.succeed("iptables -L -n | grep -q '26257'")
          node1.succeed("iptables -L -n | grep -q '26258'")
          node1.succeed("iptables -L -n | grep -q '8080'")
          node2.succeed("iptables -L -n | grep -q '26257'")
          node2.succeed("iptables -L -n | grep -q '26258'")
          node2.succeed("iptables -L -n | grep -q '8080'")
          node3.succeed("iptables -L -n | grep -q '26257'")
          node3.succeed("iptables -L -n | grep -q '26258'")
          node3.succeed("iptables -L -n | grep -q '8080'")

          # Test data replication - create table on node1, verify on others
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'")
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute=\"INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')\"")

          # Verify data is replicated to other nodes
          node2.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.11 --execute='SELECT message FROM testdb.replication_test WHERE id=1' | grep -q 'hello from cluster'")
          node3.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.12 --execute='SELECT message FROM testdb.replication_test WHERE id=1' | grep -q 'hello from cluster'")

          # Verify cluster membership - check node count (with retries)
          node1.wait_until_succeeds("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT COUNT(*) FROM crdb_internal.gossip_nodes' 2>/dev/null | grep -q '3'")
        '';
      };
    };
}
