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
      vaultwardenCertsDir = "/etc/vaultwarden/certs";

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
          name = "vaultwarden_node1";
        }
        {
          name = "vaultwarden_node2";
        }
        {
          name = "vaultwarden_node3";
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
            config.flake.nixosModules.critical-vaultwarden
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
              system.dot.vaultwarden.enable = true;
            }
          ) nodes;

          services.cockroachdb.certsDir = lib.mkForce certsDir;
          dot.cockroachdb.enable = true;
          dot.test.cockroachdb.certs = cockroachCerts;
          dot.test.cockroachdb.init = ''
            CREATE DATABASE IF NOT EXISTS testdb;
          '';

          dot.vaultwarden.enable = true;
          # Set up vaultwarden certificates using activation script
          # Copy node-specific cert and rename to generic names expected by vaultwarden module
          system.activationScripts.vaultwarden-certs = {
            text = ''
              mkdir -p ${vaultwardenCertsDir}
              cp ${cockroachCerts}/ca.crt ${vaultwardenCertsDir}/
              cp ${cockroachCerts}/client.vaultwarden_${name}.crt ${vaultwardenCertsDir}/client.vaultwarden.crt
              cp ${cockroachCerts}/client.vaultwarden_${name}.key ${vaultwardenCertsDir}/client.vaultwarden.key
              chown -R vaultwarden:vaultwarden ${vaultwardenCertsDir}
              chmod 644 ${vaultwardenCertsDir}/*.crt
              chmod 400 ${vaultwardenCertsDir}/*.key
            '';
            deps = [
              "users"
              "groups"
            ];
          };
          system.activationScripts.vaultwarden-rsa-key = {
            text = ''
              mkdir -p /var/lib/vaultwarden
              ${pkgs.openssl}/bin/openssl genrsa -out /var/lib/vaultwarden/rsa_key.pem 2048
              chown vaultwarden:vaultwarden /var/lib/vaultwarden/rsa_key.pem
              chmod 400 /var/lib/vaultwarden/rsa_key.pem
            '';
            deps = [
              "users"
              "groups"
            ];
          };
          # Mock sops secrets required by the modules
          sops.secrets = {
            "cockroach-vaultwarden-init" = {
              path = "/etc/cockroachdb/vaultwarden-init.sql";
              owner = "cockroachdb";
              group = "cockroachdb";
              mode = "0400";
            };
            "cockroach-vaultwarden-ca-public" = {
              path = "${vaultwardenCertsDir}/ca.crt";
              owner = "vaultwarden";
              group = "vaultwarden";
              mode = "0644";
            };
            "cockroach-vaultwarden-public" = {
              path = "${vaultwardenCertsDir}/client.vaultwarden.crt";
              owner = "vaultwarden";
              group = "vaultwarden";
              mode = "0644";
            };
            "cockroach-vaultwarden-private" = {
              path = "${vaultwardenCertsDir}/client.vaultwarden.key";
              owner = "vaultwarden";
              group = "vaultwarden";
              mode = "0400";
            };
            "vaultwarden-env" = {
              path = "/etc/vaultwarden/vaultwarden.env";
              owner = "vaultwarden";
              group = "vaultwarden";
              mode = "0400";
            };
            "vaultwarden-auth-key" = {
              path = "/var/lib/vaultwarden/rsa_key.pem";
              owner = "vaultwarden";
              group = "vaultwarden";
              mode = "0400";
            };
          };
          # Create cockroachdb init files
          environment.etc."cockroachdb/init.sql".text = ''
            CREATE DATABASE IF NOT EXISTS testdb;
          '';
          environment.etc."cockroachdb/vaultwarden-init.sql".text = ''
            CREATE USER IF NOT EXISTS vaultwarden_node1 WITH PASSWORD 'testpassword123';
            CREATE USER IF NOT EXISTS vaultwarden_node2 WITH PASSWORD 'testpassword123';
            CREATE USER IF NOT EXISTS vaultwarden_node3 WITH PASSWORD 'testpassword123';
            CREATE DATABASE IF NOT EXISTS vaultwarden;
            \c vaultwarden
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vaultwarden_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vaultwarden_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vaultwarden_node1;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO vaultwarden_node1;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vaultwarden_node1;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vaultwarden_node1;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vaultwarden_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vaultwarden_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vaultwarden_node2;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO vaultwarden_node2;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vaultwarden_node2;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vaultwarden_node2;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON TABLES TO vaultwarden_node3;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON SEQUENCES TO vaultwarden_node3;
            ALTER DEFAULT PRIVILEGES FOR ALL ROLES IN SCHEMA public GRANT ALL ON FUNCTIONS TO vaultwarden_node3;
            GRANT ALL ON ALL TABLES IN SCHEMA public TO vaultwarden_node3;
            GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO vaultwarden_node3;
            GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO vaultwarden_node3;
          '';
          # Create vaultwarden environment file with database connection
          environment.etc."vaultwarden/vaultwarden.env".text =
            let
              databaseUrl =
                "postgresql://"
                + "vaultwarden_${name}:testpassword123@${ip}:26257"
                + "/vaultwarden"
                + "?sslmode=verify-full"
                + "&sslrootcert=${vaultwardenCertsDir}/ca.crt"
                + "&sslcert=${vaultwardenCertsDir}/client.vaultwarden.crt"
                + "&sslkey=${vaultwardenCertsDir}/client.vaultwarden.key";
            in
            ''
              DATABASE_URL="${databaseUrl}"
              ADMIN_TOKEN="test-admin-token-${name}"
            '';

          environment.systemPackages = [
            pkgs.curl
            pkgs.cockroachdb
            pkgs.postgresql
          ];
        };
    in
    {
      # Test 1: Vaultwarden disabled - no service should be configured
      checks.test-critical-vaultwarden-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-vaultwarden-disabled";
        module = {
          imports = [
            config.flake.nixosModules.critical-vaultwarden
            config.flake.nixosModules.critical-cockroachdb
            config.flake.nixosModules.critical-cockroachdb-nixpkgs
            config.flake.nixosModules.critical-consul
            config.flake.lib.test.mockNebulaChronydTargetsModule
          ];

          # dot.vaultwarden.enable defaults to false
        };
        serviceName = "vaultwarden.service";
        configPath = "/etc/vaultwarden";
      };

      # Test 2: Multi-node vaultwarden cluster with cockroachdb backend
      checks.test-critical-vaultwarden-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-vaultwarden-cluster";
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

          # Wait for vaultwarden services to be ready (they depend on cockroachdb-init)
          node1.wait_until_succeeds("systemctl is-enabled vaultwarden.service", timeout=60)
          node2.wait_until_succeeds("systemctl is-enabled vaultwarden.service", timeout=60)
          node3.wait_until_succeeds("systemctl is-enabled vaultwarden.service", timeout=60)

          node1.wait_for_unit("vaultwarden.service", timeout=60)
          node2.wait_for_unit("vaultwarden.service", timeout=60)
          node3.wait_for_unit("vaultwarden.service", timeout=60)

          # Verify vaultwarden API is responding on all nodes via /alive endpoint
          node1.wait_until_succeeds("curl -f http://192.168.1.10:8222/alive", timeout=60)
          node2.wait_until_succeeds("curl -f http://192.168.1.11:8222/alive", timeout=60)
          node3.wait_until_succeeds("curl -f http://192.168.1.12:8222/alive", timeout=60)

          # Verify firewall ports are open
          node1.succeed("iptables -L -n | grep -q '8222'")
          node2.succeed("iptables -L -n | grep -q '8222'")
          node3.succeed("iptables -L -n | grep -q '8222'")

          # Verify vaultwarden environment file exists
          node1.succeed("test -f /etc/vaultwarden/vaultwarden.env")
          node2.succeed("test -f /etc/vaultwarden/vaultwarden.env")
          node3.succeed("test -f /etc/vaultwarden/vaultwarden.env")

          # Verify vaultwarden certificates exist
          node1.succeed("test -f ${vaultwardenCertsDir}/ca.crt")
          node1.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.crt")
          node1.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.key")
          node2.succeed("test -f ${vaultwardenCertsDir}/ca.crt")
          node2.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.crt")
          node2.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.key")
          node3.succeed("test -f ${vaultwardenCertsDir}/ca.crt")
          node3.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.crt")
          node3.succeed("test -f ${vaultwardenCertsDir}/client.vaultwarden.key")

          # Verify vaultwarden database exists in cockroachdb
          node1.succeed("cockroach sql --certs-dir=${certsDir} --host=192.168.1.10 --execute=\"SELECT datname FROM pg_database WHERE datname = 'vaultwarden'\"")
        '';
      };
    };
}
