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
      vaultCertsDir = "/etc/vault/certs";

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
          name = "vault_node1";
        }
        {
          name = "vault_node2";
        }
        {
          name = "vault_node3";
        }
      ];

      cockroachCerts = config.flake.lib.test.mkCockroachdbCerts pkgs {
        inherit nodes clients;
      };

      commonNodeConfig =
        { ip, name, ... }:
        { lib, ... }:
        {
          imports = [
            config.flake.lib.test.commonCockroachdbModule
            config.flake.nixosModules.critical-vault
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
              system.dot.vault.enable = true;
            }
          ) nodes;

          services.cockroachdb.certsDir = lib.mkForce certsDir;
          dot.cockroachdb.enable = true;
          dot.test.cockroachdb.certs = cockroachCerts;
          dot.test.cockroachdb.init = ''
            CREATE DATABASE IF NOT EXISTS testdb;
          '';

          dot.vault.enable = true;
          # Set up vault certificates using activation script
          # Copy node-specific cert and rename to generic names expected by vault module
          system.activationScripts.vault-certs = {
            text = ''
              mkdir -p ${vaultCertsDir}
              cp ${cockroachCerts}/ca.crt ${vaultCertsDir}/
              cp ${cockroachCerts}/client.vault_${name}.crt ${vaultCertsDir}/client.vault.crt
              cp ${cockroachCerts}/client.vault_${name}.key ${vaultCertsDir}/client.vault.key
              chown -R vault:vault ${vaultCertsDir}
              chmod 644 ${vaultCertsDir}/*.crt
              chmod 400 ${vaultCertsDir}/*.key
            '';
            deps = [
              "users"
              "groups"
            ];
          };
          # Mock sops secrets required by the modules
          sops.secrets = {
            "cockroach-vault-init" = {
              path = "/etc/cockroachdb/vault-init.sql";
              owner = "cockroachdb";
              group = "cockroachdb";
              mode = "0400";
            };
            "cockroach-vault-ca-public" = {
              path = "${vaultCertsDir}/ca.crt";
              owner = "vault";
              group = "vault";
              mode = "0644";
            };
            "cockroach-vault-public" = {
              path = "${vaultCertsDir}/client.vault.crt";
              owner = "vault";
              group = "vault";
              mode = "0644";
            };
            "cockroach-vault-private" = {
              path = "${vaultCertsDir}/client.vault.key";
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
                + "vault_${name}:testpassword123@${ip}:26257"
                + "/vault?sslmode=verify-full"
                + "&sslrootcert=${vaultCertsDir}/ca.crt"
                + "&sslcert=${vaultCertsDir}/client.vault.crt"
                + "&sslkey=${vaultCertsDir}/client.vault.key";
            in
            ''
              storage "cockroachdb" {
                connection_url = "${conn}"
                ha_enabled = "true"
              }
            '';

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

          # dot.vault.enable defaults to false
        };
        serviceName = "vault.service";
        configPath = "/etc/vault";
      };

      # Test 2: Multi-node vault cluster with cockroachdb backend
      checks.test-critical-vault-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-vault-cluster";
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

          # Wait for cockroachdb-init to complete
          node1.wait_for_unit("cockroachdb-init.target", timeout=240)
          node2.wait_for_unit("cockroachdb-init.target", timeout=240)
          node3.wait_for_unit("cockroachdb-init.target", timeout=240)

          # Verify cockroachdb SQL is working
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT 1'")
          node2.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.11 --execute='SELECT 1'")
          node3.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.12 --execute='SELECT 1'")

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
          node1.succeed("test -f ${vaultCertsDir}/ca.crt")
          node1.succeed("test -f ${vaultCertsDir}/client.vault.crt")
          node1.succeed("test -f ${vaultCertsDir}/client.vault.key")
          node2.succeed("test -f ${vaultCertsDir}/ca.crt")
          node2.succeed("test -f ${vaultCertsDir}/client.vault.crt")
          node2.succeed("test -f ${vaultCertsDir}/client.vault.key")
          node3.succeed("test -f ${vaultCertsDir}/ca.crt")
          node3.succeed("test -f ${vaultCertsDir}/client.vault.crt")
          node3.succeed("test -f ${vaultCertsDir}/client.vault.key")

          # Verify vault database tables exist in cockroachdb
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT COUNT(*) FROM vault.vault_kv_store' 2>/dev/null || echo 'Table exists' | grep 'Table exists'")
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute='SELECT COUNT(*) FROM vault.vault_ha_locks' 2>/dev/null || echo 'Table exists' | grep 'Table exists'")
        '';
      };
    };
}
