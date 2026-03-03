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

      # Common options mock for tests
      seaweedfsOptions = {
        dot.hardware.network.enable = pkgs.lib.mkOption {
          type = pkgs.lib.types.bool;
          default = true;
        };
        dot.hardware.monitor.enable = pkgs.lib.mkOption {
          type = pkgs.lib.types.bool;
          default = false;
        };
        dot.host.name = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "testhost";
        };
        dot.host.user = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "testuser";
        };
        dot.host.ip = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "192.168.1.10";
        };
        dot.host.hosts = pkgs.lib.mkOption {
          type = pkgs.lib.types.listOf pkgs.lib.types.attrs;
          default = [ ];
        };
        dot.nebula.interface = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "nebula-dot";
        };
        dot.browser.package = pkgs.lib.mkOption {
          type = pkgs.lib.types.package;
          default = pkgs.firefox;
        };
        dot.browser.bin = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          default = "firefox";
        };
        dot.consul.services = pkgs.lib.mkOption {
          type = pkgs.lib.types.listOf pkgs.lib.types.attrs;
          default = [ ];
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
          key = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "";
          };
        };
      };

      # Rumor specification mock submodule
      rumorSpecificationSubmodule = pkgs.lib.types.submodule {
        options = {
          imports = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.raw;
            default = [ ];
          };
          generations = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.raw;
            default = [ ];
          };
          exports = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.raw;
            default = [ ];
          };
        };
      };

      # Rumor sops mock submodule
      rumorSopsSubmodule = pkgs.lib.types.submodule {
        options = {
          keys = pkgs.lib.mkOption {
            type = pkgs.lib.types.listOf pkgs.lib.types.str;
            default = [ ];
          };
          path = pkgs.lib.mkOption {
            type = pkgs.lib.types.nullOr pkgs.lib.types.str;
            default = null;
          };
        };
      };

      # Rumor options mock
      rumorOptions = {
        rumor = pkgs.lib.mkOption {
          type = pkgs.lib.types.nullOr (
            pkgs.lib.types.submodule {
              options = {
                specification = rumorSpecificationSubmodule;
                sops = rumorSopsSubmodule;
              };
            }
          );
          default = null;
        };
      };

      # Mock systemd targets that services depend on
      mockSystemdTargets =
        { lib, ... }:
        {
          systemd.targets.nebula-online = {
            description = "Mock nebula-online target";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          };
          systemd.targets.chronyd-synced = {
            description = "Mock chronyd-synced target";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          };
        };

      # Common node configuration for seaweedfs cluster test
      commonNodeConfig = nodeIp: nodeName: {
        imports = [
          config.flake.nixosModules.critical-seaweedfs-module
          config.flake.nixosModules.critical-seaweedfs-nixpkgs
          config.flake.nixosModules.critical-cockroachdb
          config.flake.nixosModules.rumor
          mockSystemdTargets
        ];
        options = pkgs.lib.recursiveUpdate seaweedfsOptions (
          pkgs.lib.recursiveUpdate rumorOptions {
            dot.host.ip = pkgs.lib.mkOption {
              type = pkgs.lib.types.str;
              default = nodeIp;
            };
            dot.host.hosts = pkgs.lib.mkOption {
              type = pkgs.lib.types.listOf pkgs.lib.types.attrs;
              default = [
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
            };
            sops.secrets = pkgs.lib.mkOption {
              type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
              default = { };
            };
          }
        );
        config = {
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
            CREATE DATABASE IF NOT EXISTS seaweedfs;
            \c seaweedfs
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO seaweedfs_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO seaweedfs_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO seaweedfs_node1;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO seaweedfs_node1;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO seaweedfs_node1;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO seaweedfs_node1;
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
      };
    in
    {
      # Test 1: SeaweedFS disabled - no service should be configured
      checks.test-critical-seaweedfs-disabled = config.flake.lib.test.mkTest pkgs {
        name = "critical-seaweedfs-disabled";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-seaweedfs-module
            config.flake.nixosModules.critical-seaweedfs-nixpkgs
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.rumor
            mockSystemdTargets
          ];
          options = pkgs.lib.recursiveUpdate seaweedfsOptions (
            pkgs.lib.recursiveUpdate rumorOptions {
              sops.secrets = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf sopsSecretsSubmodule;
                default = { };
              };
            }
          );
          config = {
            networking.hostName = "testhost";
            users.users.testuser = {
              isNormalUser = true;
              home = "/home/testuser";
              uid = 1000;
            };
            users.groups.testuser = {
              gid = 1000;
            };
            # dot.seaweedfs.enable defaults to false
          };
        };
        script = ''
          start_all()

          # When seaweedfs is disabled, service should not be enabled
          machine.fail("systemctl is-enabled seaweedfs-master.service 2>/dev/null || systemctl status seaweedfs-master.service")

          # Verify no seaweedfs config directory is created
          machine.fail("test -d /etc/seaweedfs")
        '';
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
          import time

          start_all()

          # Wait for cockroachdb to be ready on all nodes
          node1.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled cockroachdb.service", timeout=60)

          # Wait for cockroachdb to be active
          node1.wait_for_unit("cockroachdb.service")
          node2.wait_for_unit("cockroachdb.service")
          node3.wait_for_unit("cockroachdb.service")

          # Initialize cockroachdb cluster on node1
          node1.succeed("cockroach init --host=192.168.1.10 --certs-dir=/var/lib/cockroachdb/.certs || echo 'Cluster may already be initialized'")

          # Wait for cockroachdb-init to complete
          node1.wait_for_unit("cockroachdb-init.service")

          # Verify cockroachdb SQL is working
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT 1'")

          # Wait for seaweedfs master services to be ready
          node1.wait_for_unit("seaweedfs-master.service")
          node2.wait_for_unit("seaweedfs-master.service")
          node3.wait_for_unit("seaweedfs-master.service")

          # Wait for seaweedfs volume services
          node1.wait_for_unit("seaweedfs-volume@dot.service")
          node2.wait_for_unit("seaweedfs-volume@dot.service")
          node3.wait_for_unit("seaweedfs-volume@dot.service")

          # Wait for seaweedfs filer services (depend on cockroachdb-init)
          node1.wait_for_unit("seaweedfs-filer@dot.service")
          node2.wait_for_unit("seaweedfs-filer@dot.service")
          node3.wait_for_unit("seaweedfs-filer@dot.service")

          # Give services time to fully start
          time.sleep(5)

          # Verify HTTP health endpoints are responding
          node1.succeed("curl -f http://192.168.1.10:9333/cluster/status")
          node2.succeed("curl -f http://192.168.1.11:9333/cluster/status")
          node3.succeed("curl -f http://192.168.1.12:9333/cluster/status")

          # Test filer endpoints
          node1.succeed("curl -f http://192.168.1.10:8888/")
          node2.succeed("curl -f http://192.168.1.11:8888/")
          node3.succeed("curl -f http://192.168.1.12:8888/")

          # TODO: Add file upload/download tests once basic connectivity works
          # This requires debugging to ensure proper cluster formation
        '';
      };
    };
}
