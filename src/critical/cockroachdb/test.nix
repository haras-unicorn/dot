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
          ''command_node.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)''
          ''command_node.succeed("which cockroach")''
          (node: ''
            command_node.wait_until_succeeds("""
              curl -kf --max-time 5 https://${node.dot.host.ip}:8080/health
            """, timeout=30)
          '')
          ''
            command_node.succeed("iptables -L -n | grep -q '26257'")
            command_node.succeed("iptables -L -n | grep -q '26258'")
            command_node.succeed("iptables -L -n | grep -q '8080'")
          ''
        ];
      };

      # NOTE: the non-root variant just uses sudo to read the env file so its ok to not test it
      checks.test-critical-cockroachdb-cli-root-root = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-cli-root-root";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-cli
          ];

          dot.test.cockroachdb.enable = true;
          services.cockroachdb.init.sql.scripts = [
            ''
              CREATE DATABASE IF NOT EXISTS testdb;
            ''
          ];
        };

        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot cockroachdb root sql \
              --execute 'CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'
          """)
          node1.succeed("""
            dot cockroachdb root sql \
              --execute "INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')"
          """)

          node2.succeed("""
            dot cockroachdb root sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
          node3.succeed("""
            dot cockroachdb root sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)

          node1.wait_until_succeeds("""
            dot cockroachdb root sql \
              --execute 'SELECT COUNT(*) FROM crdb_internal.gossip_nodes' 2>/dev/null \
              | grep -q '3'
          """)
        '';
      };

      checks.test-critical-cockroachdb-cli-root-non-host = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-root-non-host";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          dot.test.cockroachdb.enable = true;
          services.cockroachdb.init.sql.scripts = [
            ''
              CREATE DATABASE IF NOT EXISTS testdb;
            ''
          ];
        };

        nodes.machine = {
          imports = [
            self.nixosModules.critical-cli
          ];
          nixpkgs.config.allowUnfree = true;
        };

        dot.test.commands.enable = true;
        dot.test.commands.suffix = ''
          node1.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)
          node2.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)
          node3.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)

          machine.succeed("""
            dot cockroachdb root sql \
              --execute 'CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'
          """)
          machine.succeed("""
            dot cockroachdb root sql \
              --execute "INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')"
          """)
          machine.succeed("""
            dot cockroachdb root sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
        '';
      };

      # NOTE: the user/non-root variant just reads the file normally so its pretty much the same
      checks.test-critical-cockroachdb-cli-user-root = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-cli-user-root";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module =
          { config, ... }:
          let
            user = config.dot.host.user;
          in
          {
            imports = [
              self.nixosModules.critical-cli
            ];

            dot.test.cockroachdb.enable = true;
            services.cockroachdb.init.sql.scripts = [
              ''
                CREATE DATABASE IF NOT EXISTS testdb;

                use testdb;

                alter default privileges for all roles in schema public grant all on tables to ${user};
                alter default privileges for all roles in schema public grant all on sequences to ${user};
                alter default privileges for all roles in schema public grant all on functions to ${user};

                grant all on all tables in schema public to ${user};
                grant all on all sequences in schema public to ${user};
                grant all on all functions in schema public to ${user};

                reset database;
              ''
            ];
          };

        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)''
        ];
        dot.test.commands.suffix = ''
          node1.succeed("""
            dot cockroachdb user sql \
              --execute 'CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'
          """)
          node1.succeed("""
            dot cockroachdb user sql \
              --execute "INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')"
          """)

          node2.succeed("""
            dot cockroachdb user sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
          node3.succeed("""
            dot cockroachdb user sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
        '';
      };

      checks.test-critical-cockroachdb-cli-user-non-host = self.lib.test.mkTest pkgs {
        name = "critical-cockroachdb-user-non-host";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module =
          { config, ... }:
          let
            user = config.dot.host.user;
          in
          {
            imports = [
              self.nixosModules.critical-cli
            ];

            dot.test.cockroachdb.enable = true;
            services.cockroachdb.init.sql.scripts = [
              ''
                CREATE DATABASE IF NOT EXISTS testdb;

                use testdb;

                alter default privileges for all roles in schema public grant all on tables to ${user};
                alter default privileges for all roles in schema public grant all on sequences to ${user};
                alter default privileges for all roles in schema public grant all on functions to ${user};

                grant all on all tables in schema public to ${user};
                grant all on all sequences in schema public to ${user};
                grant all on all functions in schema public to ${user};

                reset database;
              ''
            ];
          };

        nodes.machine = {
          imports = [
            self.nixosModules.critical-cli
          ];
          nixpkgs.config.allowUnfree = true;
        };

        dot.test.commands.enable = true;
        dot.test.commands.suffix = ''
          node1.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)
          node2.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)
          node3.wait_until_succeeds("systemctl is-active dot-database-initialized.target", timeout=180)

          machine.succeed("""
            dot cockroachdb user sql \
              --execute 'CREATE TABLE IF NOT EXISTS testdb.replication_test (id INT PRIMARY KEY, message STRING)'
          """)
          machine.succeed("""
            dot cockroachdb user sql \
              --execute "INSERT INTO testdb.replication_test VALUES (1, 'hello from cluster')"
          """)
          machine.succeed("""
            dot cockroachdb user sql \
              --execute 'SELECT message FROM testdb.replication_test WHERE id=1' | \
              grep -q 'hello from cluster'
          """)
        '';
      };
    };

}
