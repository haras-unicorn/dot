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
      cockroachCerts =
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

            # Create client certificate for seaweedfs user
            cockroach cert create-client seaweedfs_node1 \
              --certs-dir=$out \
              --ca-key=$out/ca.key

            # Set permissions
            chmod 644 $out/ca.crt
            chmod 644 $out/node.crt
            chmod 400 $out/node.key
            chmod 644 $out/client.root.crt
            chmod 400 $out/client.root.key
            chmod 644 $out/client.seaweedfs_node1.crt
            chmod 400 $out/client.seaweedfs_node1.key
          '';

      # Common node configuration for seaweedfs cluster test
      commonNodeConfig = nodeIp: nodeName: {
        imports = [
          config.flake.nixosModules.critical-seaweedfs-module
          config.flake.nixosModules.critical-seaweedfs-nixpkgs
          config.flake.nixosModules.critical-cockroachdb
          config.flake.nixosModules.critical-consul
          config.flake.nixosModules.rumor
          config.flake.lib.test.commonDotOptionsModule
          config.flake.lib.test.mockNebulaChronydTargetsModule
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
                seaweedfs = {
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
                seaweedfs = {
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
                seaweedfs = {
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
        dot.seaweedfs.enable = true;

        # Set up cockroachdb certificates using activation script
        system.activationScripts.cockroachdb-certs = {
          text = ''
            mkdir -p /var/lib/cockroachdb/.certs
            cp ${cockroachCerts}/ca.crt /var/lib/cockroachdb/.certs/
            cp ${cockroachCerts}/node.crt /var/lib/cockroachdb/.certs/
            cp ${cockroachCerts}/node.key /var/lib/cockroachdb/.certs/
            cp ${cockroachCerts}/client.root.crt /var/lib/cockroachdb/.certs/
            cp ${cockroachCerts}/client.root.key /var/lib/cockroachdb/.certs/
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

        # Mock sops secrets required by the modules
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

        # Create cockroachdb init files
        environment.etc."cockroachdb/init.sql".text = ''
          CREATE DATABASE IF NOT EXISTS testdb;
        '';

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

        # Create seaweedfs filer environment file
        environment.etc."seaweedfs/filer.env".text = ''
          WEED_POSTGRES_PASSWORD=testpassword123
        '';

        # Ensure users exist
        users.users.cockroachdb = {
          isSystemUser = true;
          group = "cockroachdb";
          home = "/var/lib/cockroachdb";
        };
        users.groups.cockroachdb = { };

        users.users.seaweedfs = {
          isSystemUser = true;
          group = "seaweedfs";
          home = "/var/lib/seaweedfs";
        };
        users.groups.seaweedfs = { };

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
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.critical-consul
            config.flake.lib.test.mockNebulaChronydTargetsModule
          ];

          users.users.testuser = {
            isNormalUser = true;
            home = "/home/testuser";
            uid = 1000;
          };
          users.groups.testuser = {
            gid = 1000;
          };
        };
        serviceName = "seaweedfs.service";
        configPath = "/etc/seaweedfs";
      };

      # Test 2: Multi-node seaweedfs cluster with cockroachdb
      checks.test-critical-seaweedfs-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-seaweedfs-cluster";
        nodes = {
          node1 = commonNodeConfig "192.168.1.10" "node1";
          node2 = commonNodeConfig "192.168.1.11" "node2";
          node3 = commonNodeConfig "192.168.1.12" "node3";
        };
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
          node1.wait_for_unit("cockroachdb-init.target", timeout=180)
          node2.wait_for_unit("cockroachdb-init.target", timeout=180)
          node3.wait_for_unit("cockroachdb-init.target", timeout=180)

          # Verify cockroachdb SQL is working
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.12 --execute='SELECT 1'")

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
