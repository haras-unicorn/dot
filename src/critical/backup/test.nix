{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-physical-backup-restore = self.lib.test.mkTest pkgs {
        name = "critical-physical-backup-restore";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-backup
            self.nixosModules.critical-cli
          ];

          dot.backup.enable = true;
          dot.test.cockroachdb.enable = true;
          dot.test.seaweedfs.enable = true;

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
          ''command_node.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)''
          ''command_node.wait_until_succeeds("systemctl is-active dot-filesystem-initialized.target", timeout=180)''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)

          node1.succeed("""
            echo 'SeaweedFS backup test content' > /tmp/sw-testfile.txt
          """)
          node1.succeed("""
            curl -F file=@/tmp/sw-testfile.txt http://192.168.1.10:8888/testbackup/
          """)
          node1.wait_until_succeeds("""
            curl -f http://192.168.1.10:8888/testbackup/sw-testfile.txt | \
              grep -q 'SeaweedFS backup test content'
          """, timeout=60)

          backup_output = node1.succeed("cd /tmp && dot-physical-backup")
          quoted_password = backup_output.split(" ")[-1].strip()
          node1.wait_for_unit("dot-database-initialized.target", timeout=180)
          node1.wait_for_unit("dot-filesystem-initialized.target", timeout=180)

          node1.succeed("dot cockroachdb root sql --execute 'DROP DATABASE testdb CASCADE'")
          node1.fail("dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1'")
          node1.succeed("""
            curl -X DELETE http://192.168.1.10:8888/testbackup/sw-testfile.txt
          """)
          node1.fail("""
            curl -f http://192.168.1.10:8888/testbackup/sw-testfile.txt
          """)

          node1.succeed(f"cd /tmp && echo {quoted_password} | dot-physical-restore")
          node1.wait_for_unit("dot-database-initialized.target", timeout=180)
          node1.wait_for_unit("dot-filesystem-initialized.target", timeout=180)

          node1.succeed("""
            dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)
          node1.succeed("""
            curl -sf http://192.168.1.10:8888/testbackup/sw-testfile.txt | \
              grep -q 'SeaweedFS backup test content'
          """)
        '';
      };

      checks.test-critical-logical-backup-restore = self.lib.test.mkTest pkgs {
        name = "critical-logical-backup-restore";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-backup
            self.nixosModules.critical-cli
          ];

          dot.backup.enable = true;
          dot.test.cockroachdb.enable = true;
          dot.test.seaweedfs.enable = true;

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
          ''command_node.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)''
          ''command_node.wait_until_succeeds("systemctl is-active dot-filesystem-initialized.target", timeout=180)''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)

          node1.succeed("""
            echo 'SeaweedFS backup test content' > /tmp/sw-testfile.txt
          """)
          node1.succeed("""
            curl -F file=@/tmp/sw-testfile.txt http://192.168.1.10:8888/testbackup/
          """)
          node1.wait_until_succeeds("""
            curl -f http://192.168.1.10:8888/testbackup/sw-testfile.txt | \
              grep -q 'SeaweedFS backup test content'
          """, timeout=60)

          backup_output = node1.succeed("cd /tmp && dot-logical-backup")
          quoted_password = backup_output.split(" ")[-1].strip()
          node1.wait_for_unit("dot-database-initialized.target", timeout=180)
          node1.wait_for_unit("dot-filesystem-initialized.target", timeout=180)

          node1.succeed("dot cockroachdb root sql --execute 'DROP DATABASE testdb CASCADE'")
          node1.fail("dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1'")
          node1.succeed("""
            curl -X DELETE http://192.168.1.10:8888/testbackup/sw-testfile.txt
          """)
          node1.fail("""
            curl -f http://192.168.1.10:8888/testbackup/sw-testfile.txt
          """)

          node1.succeed(f"cd /tmp && echo {quoted_password} | dot-logical-restore")
          node1.wait_for_unit("dot-database-initialized.target", timeout=180)
          node1.wait_for_unit("dot-filesystem-initialized.target", timeout=180)

          node1.succeed("""
            dot cockroachdb root sql --execute 'SELECT message FROM testdb.backup_test WHERE id=1' | \
              grep -q 'test data for backup'
          """)
          node1.succeed("""
            curl -sf http://192.168.1.10:8888/testbackup/sw-testfile.txt | \
              grep -q 'SeaweedFS backup test content'
          """)
        '';
      };
    };
}
