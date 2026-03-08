{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-cockroachdb-disabled = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-disabled";
        dot.test.disabledService.module = { };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "cockroachdb.service";
        dot.test.disabledService.config = "/etc/cockroachdb";
      };

      checks.test-critical-cockroachdb-cluster = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-cluster";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          dot.test.cockroachdb.enable = true;
          services.cockroachdb.init.sql.scripts = [
            ''
              CREATE DATABASE IF NOT EXISTS testdb;
            ''
          ];
        };

        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)''
          ''command_node.wait_for_unit("cockroachdb.service", timeout=60)''
          ''command_node.wait_for_unit("dot-database-initialized.target", timeout=180)''
          ''command_node.succeed("which cockroach")''
          (node: ''
            command_node.wait_until_succeeds("""
              curl -kf --max-time 5 https://${node.dot.host.ip}:8080/health
            """, timeout=30)
          '')
          ''command_node.succeed("dot-cockroach-root sql --execute='SELECT 1'")''
          ''
            command_node.succeed("iptables -L -n | grep -q '26257'")
            command_node.succeed("iptables -L -n | grep -q '26258'")
            command_node.succeed("iptables -L -n | grep -q '8080'")
          ''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot-cockroach-root sql \
              --execute='CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'
          """)
          node1.succeed("""
            dot-cockroach-root sql \
              --execute="INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')"
          """)

          node2.succeed("""
            dot-cockroach-root sql \
              --execute='SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
          node3.succeed("""
            dot-cockroach-root sql \
              --execute='SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)

          node1.wait_until_succeeds("""
            dot-cockroach-root sql \
              --execute='SELECT COUNT(*) FROM crdb_internal.gossip_nodes' 2>/dev/null \
              | grep -q '3'
          """)
        '';
      };
    };
}
