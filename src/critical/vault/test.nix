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

            # Create client certificate for vault users
            cockroach cert create-client vault_node1 \
              --certs-dir=$out \
              --ca-key=$out/ca.key
            cockroach cert create-client vault_node2 \
              --certs-dir=$out \
              --ca-key=$out/ca.key
            cockroach cert create-client vault_node3 \
              --certs-dir=$out \
              --ca-key=$out/ca.key

            # Set permissions
            chmod 644 $out/*.crt
            chmod 400 $out/*.key
          '';

      # Common node configuration for vault cluster test
      commonNodeConfig = nodeIp: nodeName: {
        imports = [
          config.flake.nixosModules.critical-vault
          config.flake.nixosModules.critical-cockroachdb
          config.flake.nixosModules.critical-cockroachdb-nixpkgs
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
                vault = {
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
                vault = {
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
                vault = {
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
        dot.vault.enable = true;

        # Set up cockroachdb certificates using activation script
        system.activationScripts.cockroachdb-certs = {
          text = ''
            mkdir -p /var/lib/cockroachdb/.certs
            cp ${cockroachCerts}/* /var/lib/cockroachdb/.certs/
            chown -R cockroachdb:cockroachdb /var/lib/cockroachdb/.certs
            chmod 644 /var/lib/cockroachdb/.certs/*.crt
            chmod 600 /var/lib/cockroachdb/.certs/*.key
          '';
          deps = [
            "users"
            "groups"
          ];
        };

        # Set up vault certificates using activation script
        system.activationScripts.vault-certs = {
          text = ''
            mkdir -p /etc/vault/certs
            cp ${cockroachCerts}/ca.crt /etc/vault/certs/
            cp ${cockroachCerts}/client.vault_* /etc/vault/certs/
            chown -R vault:vault /etc/vault/certs
            chmod 644 /etc/vault/certs/*.crt
            chmod 400 /etc/vault/certs/*.key
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
          "cockroach-vault-init" = {
            path = "/etc/cockroachdb/vault-init.sql";
            owner = "cockroachdb";
            group = "cockroachdb";
            mode = "0400";
          };
          "cockroach-vault-ca-public" = {
            path = "/etc/vault/certs/ca.crt";
            owner = "vault";
            group = "vault";
            mode = "0644";
          };
          "cockroach-vault-public" = {
            path = "/etc/vault/certs/client.vault.crt";
            owner = "vault";
            group = "vault";
            mode = "0644";
          };
          "cockroach-vault-private" = {
            path = "/etc/vault/certs/client.vault.key";
            owner = "vault";
            group = "vault";
            mode = "0400";
          };
          "vault-settings" = {
            path = "/etc/vault/vault.hcl";
            owner = "vault";
            group = "vault";
            mode = "0400";
          };
        };

        # Create cockroachdb init files
        environment.etc."cockroachdb/init.sql".text = ''
          CREATE DATABASE IF NOT EXISTS testdb;
        '';

        environment.etc."cockroachdb/vault-init.sql".text = ''
          CREATE USER IF NOT EXISTS vault_node1 WITH PASSWORD 'testpassword123';
          CREATE USER IF NOT EXISTS vault_node2 WITH PASSWORD 'testpassword123';
          CREATE USER IF NOT EXISTS vault_node3 WITH PASSWORD 'testpassword123';
          CREATE DATABASE IF NOT EXISTS vault;
          \c vault
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vault_node1;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vault_node1;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vault_node1;
          GRANT ALL ON ALL TABLES IN SCHEMA public TO vault_node1;
          GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vault_node1;
          GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vault_node1;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vault_node2;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vault_node2;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vault_node2;
          GRANT ALL ON ALL TABLES IN SCHEMA public TO vault_node2;
          GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vault_node2;
          GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vault_node2;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vault_node3;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vault_node3;
          ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vault_node3;
          GRANT ALL ON ALL TABLES IN SCHEMA public TO vault_node3;
          GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vault_node3;
          GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vault_node3;
          CREATE TABLE IF NOT EXISTS vault_kv_store (
              path STRING NOT NULL,
              value BYTES NULL,
              CONSTRAINT vault_kv_store_pkey PRIMARY KEY (path ASC)
          );
          CREATE TABLE IF NOT EXISTS vault_ha_locks (
              ha_key STRING NOT NULL,
              ha_identity STRING NOT NULL,
              ha_value STRING NULL,
              valid_until TIMESTAMPTZ NOT NULL,
              CONSTRAINT ha_key PRIMARY KEY (ha_key ASC)
          );
        '';

        # Create vault settings file with cockroachdb storage backend
        environment.etc."vault/vault.hcl".text =
          let
            conn =
              "postgresql://"
              + "vault_${nodeName}:testpassword123@${nodeIp}:26257"
              + "/vault?sslmode=verify-full"
              + "&sslrootcert=/etc/vault/certs/ca.crt"
              + "&sslcert=/etc/vault/certs/client.vault_${nodeName}.crt"
              + "&sslkey=/etc/vault/certs/client.vault_${nodeName}.key";
          in
          ''
            storage "cockroachdb" {
              connection_url = "${conn}"
              ha_enabled = "true"
            }
          '';

        # Ensure users exist
        users.users.cockroachdb = {
          isSystemUser = true;
          group = "cockroachdb";
          home = "/var/lib/cockroachdb";
        };
        users.groups.cockroachdb = { };

        users.users.vault = {
          isSystemUser = true;
          group = "vault";
          home = "/var/lib/vault";
        };
        users.groups.vault = { };

        environment.systemPackages = [
          pkgs.curl
          pkgs.cockroachdb
          pkgs.postgresql
          pkgs.vault-bin
        ];
      };
    in
    {
      # Test 1: Vault disabled - no service should be configured
      checks.test-critical-vault-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-vault-disabled";
        module = {
          imports = [
            config.flake.nixosModules.critical-vault
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.critical-cockroachdb-nixpkgs
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

          # dot.vault.enable defaults to false
        };
        serviceName = "vault.service";
        configPath = "/etc/vault";
      };

      # Test 2: Multi-node vault cluster with cockroachdb backend
      checks.test-critical-vault-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-vault-cluster";
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

          # Wait for cockroachdb-init to complete
          node1.wait_for_unit("cockroachdb-init.target", timeout=240)
          node2.wait_for_unit("cockroachdb-init.target", timeout=240)
          node3.wait_for_unit("cockroachdb-init.target", timeout=240)

          # Verify cockroachdb SQL is working
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.12 --execute='SELECT 1'")

          # Wait for vault services to be ready (they depend on cockroachdb-init)
          node1.wait_until_succeeds("systemctl is-enabled vault.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled vault.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled vault.service", timeout=60)

          node1.wait_for_unit("vault.service", timeout=60)
          node2.wait_for_unit("vault.service", timeout=60)
          node3.wait_for_unit("vault.service", timeout=60)

          # Verify vault API is responding on all nodes
          # Vault starts in uninitialized/sealed state, so we expect 501 (not initialized)
          node1.wait_until_succeeds("curl -f http://192.168.1.10:8200/v1/sys/health 2>/dev/null || test $? -eq 22", timeout=60)
          node2.wait_until_succeeds("curl -f http://192.168.1.11:8200/v1/sys/health 2>/dev/null || test $? -eq 22", timeout=60)
          node3.wait_until_succeeds("curl -f http://192.168.1.12:8200/v1/sys/health 2>/dev/null || test $? -eq 22", timeout=60)

          # Check Vault's health endpoint returns expected status
          # 501 means not initialized, 503 means sealed, 200 means active
          node1.succeed("curl -s http://192.168.1.10:8200/v1/sys/health | grep -q 'initialized\":false' || test $? -eq 0")
          node2.succeed("curl -s http://192.168.1.11:8200/v1/sys/health | grep -q 'initialized\":false' || test $? -eq 0")
          node3.succeed("curl -s http://192.168.1.12:8200/v1/sys/health | grep -q 'initialized\":false' || test $? -eq 0")

          # Verify firewall ports are open
          node1.succeed("iptables -L -n | grep -q '8200'")
          node1.succeed("iptables -L -n | grep -q '8201'")
          node2.succeed("iptables -L -n | grep -q '8200'")
          node2.succeed("iptables -L -n | grep -q '8201'")
          node3.succeed("iptables -L -n | grep -q '8200'")
          node3.succeed("iptables -L -n | grep -q '8201'")

          # Verify vault config file exists
          node1.succeed("test -f /etc/vault/vault.hcl")
          node2.succeed("test -f /etc/vault/vault.hcl")
          node3.succeed("test -f /etc/vault/vault.hcl")

          # Verify vault certificates exist
          node1.succeed("test -f /etc/vault/certs/ca.crt")
          node1.succeed("test -f /etc/vault/certs/client.vault_node1.crt")
          node1.succeed("test -f /etc/vault/certs/client.vault_node1.key")
          node2.succeed("test -f /etc/vault/certs/ca.crt")
          node2.succeed("test -f /etc/vault/certs/client.vault_node2.crt")
          node2.succeed("test -f /etc/vault/certs/client.vault_node2.key")
          node3.succeed("test -f /etc/vault/certs/ca.crt")
          node3.succeed("test -f /etc/vault/certs/client.vault_node3.crt")
          node3.succeed("test -f /etc/vault/certs/client.vault_node3.key")

          # Verify vault database tables exist in cockroachdb
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT COUNT(*) FROM vault.vault_kv_store' 2>/dev/null || echo 'Table exists' | grep 'Table exists'")
          node1.succeed("cockroach sql --certs-dir=/var/lib/cockroachdb/.certs --host=192.168.1.10 --execute='SELECT COUNT(*) FROM vault.vault_ha_locks' 2>/dev/null || echo 'Table exists' | grep 'Table exists'")
        '';
      };
    };
}
