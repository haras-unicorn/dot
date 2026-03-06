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

      clients = [
        {
          name = "seaweedfs_node1";
        }
        {
          name = "seaweedfs_node2";
        }
        {
          name = "seaweedfs_node3";
        }
      ];

      certs = config.flake.lib.test.mkCockroachdbCerts pkgs {
        inherit nodes clients;
      };

      commonNodeConfig =
        { ip, name, ... }:
        { lib, ... }:
        {
          imports = [
            config.flake.lib.test.commonCockroachdbModule
            config.flake.nixosModules.critical-seaweedfs-module
            config.flake.nixosModules.critical-seaweedfs-nixpkgs
          ];

          dot.host.name = name;
          networking.hostName = name;
          dot.host.ip = ip;
          networking.interfaces.eth1.ipv4.addresses = [
            {
              address = ip;
              prefixLength = 24;
            }
          ];
          dot.host.hosts = builtins.map (
            { ip, ... }:
            {
              inherit ip;
              system.dot.cockroachdb.enable = true;
              system.dot.seaweedfs.enable = true;
            }
          ) nodes;

          services.cockroachdb.certsDir = lib.mkForce certsDir;
          dot.cockroachdb.enable = true;
          dot.test.cockroachdb.certs = certs;
          dot.test.cockroachdb.init = ''
            CREATE DATABASE IF NOT EXISTS testdb;
          '';

          dot.seaweedfs.enable = true;
          sops.secrets = {
            "cockroach-seaweedfs-init" = {
              path = "/etc/cockroachdb/seaweedfs-init.sql";
              owner = "cockroachdb";
              group = "cockroachdb";
              mode = "0400";
            };
            "seaweedfs-filer-env" = {
              path = "/etc/seaweedfs/filer.env";
              owner = "seaweedfs";
              group = "seaweedfs";
              mode = "0400";
            };
          };
          environment.etc."cockroachdb/seaweedfs-init.sql".text = ''
            CREATE USER IF NOT EXISTS seaweedfs_node1 WITH PASSWORD 'testpassword123';
            CREATE USER IF NOT EXISTS seaweedfs_node2 WITH PASSWORD 'testpassword123';
            CREATE USER IF NOT EXISTS seaweedfs_node3 WITH PASSWORD 'testpassword123';
            CREATE DATABASE IF NOT EXISTS seaweedfs;
            \c seaweedfs
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO seaweedfs_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO seaweedfs_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO seaweedfs_node1;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO seaweedfs_node1;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO seaweedfs_node1;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO seaweedfs_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO seaweedfs_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO seaweedfs_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO seaweedfs_node2;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO seaweedfs_node2;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO seaweedfs_node2;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO seaweedfs_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO seaweedfs_node3;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO seaweedfs_node3;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO seaweedfs_node3;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO seaweedfs_node3;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO seaweedfs_node3;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO seaweedfs_node3;
            CREATE TABLE IF NOT EXISTS filemeta (
              dirhash     bigint,
              name        varchar(65535),
              directory   varchar(65535),
              meta        bytea,
              PRIMARY KEY (dirhash, name)
            );
          '';
          environment.etc."seaweedfs/filer.env".text = ''
            WEED_POSTGRES_PASSWORD=testpassword123
          '';

          environment.systemPackages = [
            pkgs.curl
            pkgs.cockroachdb
            pkgs.postgresql
            pkgs.seaweedfs
          ];
        };
    in
    {
      # Test 1: SeaweedFS disabled - no service should be configured
      checks.test-critical-seaweedfs-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-seaweedfs-disabled";
        module = {
          imports = [
            config.flake.nixosModules.critical-seaweedfs-module
            config.flake.nixosModules.critical-seaweedfs-nixpkgs
            config.flake.nixosModules.critical-cockroachdb-nixpkgs
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.critical-consul
            config.flake.lib.test.mockNebulaChronydTargetsModule
          ];
        };
        serviceName = "seaweedfs.service";
        configPath = "/etc/seaweedfs";
      };

      # Test 2: Multi-node seaweedfs cluster with cockroachdb
      checks.test-critical-seaweedfs-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-seaweedfs-cluster";
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

          # Wait for cockroachdb to be ready on all nodes
          node1.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)

          # Wait for cockroachdb to be active
          node1.wait_for_unit("cockroachdb.service", timeout=60)
          node2.wait_for_unit("cockroachdb.service", timeout=60)
          node3.wait_for_unit("cockroachdb.service", timeout=60)

          # Wait for cockroachdb-init to complete (check target is reached)
          node1.wait_for_unit("cockroachdb-init.target", timeout=240)
          node2.wait_for_unit("cockroachdb-init.target", timeout=240)
          node3.wait_for_unit("cockroachdb-init.target", timeout=240)

          # Verify cockroachdb SQL is working
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.12 --execute='SELECT 1'")

          # Wait for seaweedfs master services to be ready
          node1.wait_for_unit("seaweedfs-master.service", timeout=60)
          node2.wait_for_unit("seaweedfs-master.service", timeout=60)
          node3.wait_for_unit("seaweedfs-master.service", timeout=60)

          # Wait for seaweedfs volume services
          node1.wait_for_unit("seaweedfs-volume@dot.service", timeout=60)
          node2.wait_for_unit("seaweedfs-volume@dot.service", timeout=60)
          node3.wait_for_unit("seaweedfs-volume@dot.service", timeout=60)

          # Wait for seaweedfs filer services (depend on cockroachdb-init)
          node1.wait_until_succeeds("systemctl is-enabled seaweedfs-filer@dot.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled seaweedfs-filer@dot.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled seaweedfs-filer@dot.service", timeout=60)

          # Verify HTTP health endpoints are responding
          node1.wait_until_succeeds("curl -f http://192.168.1.10:9333/cluster/status", timeout=60)
          node2.wait_until_succeeds("curl -f http://192.168.1.11:9333/cluster/status", timeout=60)
          node3.wait_until_succeeds("curl -f http://192.168.1.12:9333/cluster/status", timeout=60)

          # Test filer endpoints
          node1.wait_until_succeeds("curl -f http://192.168.1.10:8888/", timeout=60)
          node2.wait_until_succeeds("curl -f http://192.168.1.11:8888/", timeout=60)
          node3.wait_until_succeeds("curl -f http://192.168.1.12:8888/", timeout=60)

          # Test file upload and download across cluster
          # Create a test file on node1
          node1.succeed("echo 'Hello from SeaweedFS cluster test' > /tmp/testfile.txt")

          # Upload file via node1's filer
          node1.succeed("curl -F file=@/tmp/testfile.txt http://192.168.1.10:8888/testfolder/")

          # Verify file is accessible via node2 and node3 (replication)
          node2.wait_until_succeeds("curl -f http://192.168.1.11:8888/testfolder/testfile.txt | grep 'Hello from SeaweedFS cluster test'", timeout=60)
          node3.wait_until_succeeds("curl -f http://192.168.1.12:8888/testfolder/testfile.txt | grep 'Hello from SeaweedFS cluster test'", timeout=60)

          # Test directory listing
          node1.succeed("curl -f http://192.168.1.10:8888/testfolder/ | grep 'testfile.txt'")

          # Test cluster topology - verify all masters see each other
          node1.succeed("curl -f http://192.168.1.10:9333/cluster/status | grep -q '192.168.1.11'")
          node1.succeed("curl -f http://192.168.1.10:9333/cluster/status | grep -q '192.168.1.12'")

          # Test volume server status
          node1.succeed("curl -f http://192.168.1.10:8081/status | grep -q 'Version'")
          node2.succeed("curl -f http://192.168.1.11:8081/status | grep -q 'Version'")
          node3.succeed("curl -f http://192.168.1.12:8081/status | grep -q 'Version'")
        '';
      };
    };
}
