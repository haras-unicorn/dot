{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-backup = self.lib.test.mkTest pkgs {
        name = "critical-backup";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-backup
          ];

          dot.backup.enable = true;
          dot.test.cockroachdb.enable = true;

          services.cockroachdb.init.sql.scripts = [
            ''
              CREATE DATABASE IF NOT EXISTS testdb;
              CREATE TABLE IF NOT EXISTS testdb.backup_test (id INT PRIMARY KEY, message STRING);
              INSERT INTO testdb.backup_test VALUES (1, 'test data for backup');
            ''
          ];
        };

        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_for_unit("dot-database-initialized.target", timeout=180)''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot-cockroach-root sql --execute='SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)

          backup_output = node1.succeed("cd /tmp && dot-physical-backup")
          quoted_password = backup_output.split(" ")[-1].strip()

          node1.succeed("dot-cockroach-root sql --execute='DROP DATABASE testdb CASCADE'")
          node1.fail("dot-cockroach-root sql --execute='SELECT message FROM testdb.backup_test WHERE id=1'")

          node1.succeed(f"cd /tmp && echo {quoted_password} | dot-physical-restore")

          node1.succeed("""
            dot-cockroach-root sql --execute='SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)
        '';
      };
    };
}
