{ config, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    let
      # Generate test certificates for traefik using openssl
      testCerts =
        pkgs.runCommand "traefik-test-certs"
          {
            nativeBuildInputs = [ pkgs.openssl ];
          }
          ''
            mkdir -p $out

            # Generate CA key and certificate
            openssl genrsa -out $out/ca.key 2048
            openssl req -new -x509 -days 365 -key $out/ca.key \
              -subj "/C=US/ST=Test/L=Test/O=Dot/CN=Traefik Test CA" \
              -out $out/ca.crt

            # Generate traefik server key and CSR
            openssl genrsa -out $out/traefik.key 2048
            openssl req -new -key $out/traefik.key \
              -subj "/C=US/ST=Test/L=Test/O=Dot/CN=testhost.dot" \
              -out $out/traefik.csr

            # Create extensions file for SAN
            cat > $out/extensions.cnf << EOF
            basicConstraints=CA:FALSE
            keyUsage = digitalSignature, keyEncipherment
            extendedKeyUsage = serverAuth, clientAuth
            subjectAltName = @alt_names

            [alt_names]
            DNS.1 = *.service.consul
            DNS.2 = testhost.dot
            DNS.3 = localhost
            IP.1 = 192.168.1.10
            IP.2 = 192.168.1.11
            IP.3 = 192.168.1.12
            IP.4 = 127.0.0.1
            EOF

            # Sign the traefik certificate with the CA
            openssl x509 -req -days 365 -in $out/traefik.csr \
              -CA $out/ca.crt -CAkey $out/ca.key -CAcreateserial \
              -extfile $out/extensions.cnf \
              -out $out/traefik.crt

            # Set permissions in the output
            chmod 644 $out/ca.crt
            chmod 644 $out/traefik.crt
            chmod 400 $out/traefik.key
          '';

      # Get helper functions from test library
      inherit (config.flake.lib.test)
        commonDotOptionsModule
        sopsSecretsModule
        mockNebulaChronydTargetsModule
        ;

      traefikCertsDir = "/etc/traefik/certs";
      consulCertsDir = "/etc/consul/certs";

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

      # Create a simple backend script that responds with the node name
      backendScript =
        name:
        pkgs.writeShellScript "test-backend-${name}" ''
                  ${pkgs.python3}/bin/python3 -c "
          import http.server
          import socketserver
          import sys

          PORT = 8080
          NODE_NAME = '${name}'

          class Handler(http.server.BaseHTTPRequestHandler):
              def do_GET(self):
                  if self.path == '/health':
                      self.send_response(200)
                      self.send_header('Content-type', 'text/plain')
                      self.end_headers()
                      self.wfile.write(b'OK')
                  else:
                      self.send_response(200)
                      self.send_header('Content-type', 'text/plain')
                      self.end_headers()
                      self.wfile.write(f'Response from {NODE_NAME}'.encode())
              def log_message(self, format, *args):
                  pass  # Suppress logs

          with socketserver.TCPServer(('0.0.0.0', PORT), Handler) as httpd:
              httpd.serve_forever()
          "
        '';

      commonNodeConfig =
        { ip, name, ... }:
        { lib, ... }:
        {
          imports = [
            config.flake.nixosModules.critical-traefik
            config.flake.nixosModules.critical-consul
            config.flake.nixosModules.rumor
            mockNebulaChronydTargetsModule
            commonDotOptionsModule
            sopsSecretsModule
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
              system.dot.traefik.enable = true;
              system.dot.consul.enable = true;
            }
          ) nodes;

          dot.traefik.enable = true;
          dot.consul.enable = true;

          # Register a test backend service in consul for load balancing tests
          dot.consul.services = [
            {
              name = "test-backend";
              port = 8080;
              address = ip;
              tags = [ "traefik.enable=true" ];
              check = {
                http = "http://${ip}:8080/health";
                interval = "10s";
                timeout = "5s";
              };
            }
          ];

          # Create a simple test backend service
          systemd.services.test-backend = {
            description = "Test backend service for traefik load balancing";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              Type = "simple";
              ExecStart = backendScript name;
              Restart = "always";
              RestartSec = 1;
            };
          };

          # Mock sops secrets for both traefik and consul
          sops.secrets = {
            "traefik-ca-public" = pkgs.lib.mkForce {
              path = "${traefikCertsDir}/ca.crt";
              owner = "traefik";
              group = "traefik";
              mode = "0644";
            };
            "traefik-public" = pkgs.lib.mkForce {
              path = "${traefikCertsDir}/traefik.crt";
              owner = "traefik";
              group = "traefik";
              mode = "0644";
            };
            "traefik-private" = pkgs.lib.mkForce {
              path = "${traefikCertsDir}/traefik.key";
              owner = "traefik";
              group = "traefik";
              mode = "0400";
            };
            "consul-config" = pkgs.lib.mkForce {
              path = "/etc/consul/config.json";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
            "consul-ca-public" = pkgs.lib.mkForce {
              key = "openssl-ca-public";
              path = "${consulCertsDir}/ca.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-public" = pkgs.lib.mkForce {
              path = "${consulCertsDir}/consul.crt";
              owner = "consul";
              group = "consul";
              mode = "0644";
            };
            "consul-private" = pkgs.lib.mkForce {
              path = "${consulCertsDir}/consul.key";
              owner = "consul";
              group = "consul";
              mode = "0400";
            };
          };

          # Place certificates
          environment.etc."traefik/certs/ca.crt".source = "${testCerts}/ca.crt";
          environment.etc."traefik/certs/traefik.crt".source = "${testCerts}/traefik.crt";
          environment.etc."traefik/certs/traefik.key".source = "${testCerts}/traefik.key";
          environment.etc."consul/certs/ca.crt".source = "${testCerts}/ca.crt";
          environment.etc."consul/certs/consul.crt".source = "${testCerts}/traefik.crt";
          environment.etc."consul/certs/consul.key".source = "${testCerts}/traefik.key";

          # Create consul config file
          environment.etc."consul/config.json".text = ''
            {
              "encrypt": "cg8St28zD8jR2lj0vC0N4Q==",
              "acl": {
                "enabled": false
              }
            }
          '';

          # Ensure users exist
          users.users.traefik = {
            isSystemUser = true;
            group = "traefik";
          };
          users.groups.traefik = { };

          users.users.consul = {
            isSystemUser = true;
            group = "consul";
          };
          users.groups.consul = { };

          environment.systemPackages = [ pkgs.curl ];
        };
    in
    {
      # Test 1: Traefik disabled - no service should be configured
      checks.test-critical-traefik-disabled = config.flake.lib.test.mkDisabledServiceTest pkgs {
        name = "critical-traefik-disabled";
        module = {
          imports = [
            config.flake.nixosModules.critical-traefik
            config.flake.nixosModules.critical-consul
            config.flake.nixosModules.rumor
            mockNebulaChronydTargetsModule
          ];

          # dot.traefik.enable defaults to false
        };
        serviceName = "traefik.service";
        configPath = "/etc/traefik";
      };

      # Test 2: Multi-node traefik cluster with consul and load balancing
      checks.test-critical-traefik-cluster = config.flake.lib.test.mkTest pkgs {
        name = "critical-traefik-cluster";
        nodes = builtins.mapAttrs (_: commonNodeConfig) (
          builtins.listToAttrs (
            builtins.map (node: {
              name = node.name;
              value = node;
            }) nodes
          )
        );
        script = ''
          import time

          start_all()

          # Wait for network to be online on all nodes
          node1.wait_for_unit("network-online.target")
          node2.wait_for_unit("network-online.target")
          node3.wait_for_unit("network-online.target")

          # Wait for backend services to start
          node1.wait_for_unit("test-backend.service")
          node2.wait_for_unit("test-backend.service")
          node3.wait_for_unit("test-backend.service")

          # Wait for consul services to start on all nodes
          node1.wait_for_unit("consul.service")
          node2.wait_for_unit("consul.service")
          node3.wait_for_unit("consul.service")

          # Give consul time to form the cluster
          time.sleep(15)

          # Wait for traefik services to start on all nodes
          node1.wait_for_unit("traefik.service")
          node2.wait_for_unit("traefik.service")
          node3.wait_for_unit("traefik.service")

          # Give traefik time to initialize and sync with consul
          time.sleep(10)

          # Verify traefik service is enabled on all nodes
          node1.succeed("systemctl is-enabled traefik.service")
          node2.succeed("systemctl is-enabled traefik.service")
          node3.succeed("systemctl is-enabled traefik.service")

          # Verify certificate directory exists on all nodes
          node1.succeed("test -d ${traefikCertsDir}")
          node2.succeed("test -d ${traefikCertsDir}")
          node3.succeed("test -d ${traefikCertsDir}")

          # Verify certificates exist on all nodes
          node1.succeed("test -f ${traefikCertsDir}/ca.crt")
          node1.succeed("test -f ${traefikCertsDir}/traefik.crt")
          node1.succeed("test -f ${traefikCertsDir}/traefik.key")
          node2.succeed("test -f ${traefikCertsDir}/ca.crt")
          node2.succeed("test -f ${traefikCertsDir}/traefik.crt")
          node2.succeed("test -f ${traefikCertsDir}/traefik.key")
          node3.succeed("test -f ${traefikCertsDir}/ca.crt")
          node3.succeed("test -f ${traefikCertsDir}/traefik.crt")
          node3.succeed("test -f ${traefikCertsDir}/traefik.key")

          # Verify firewall port 443 is open on all nodes
          node1.succeed("iptables -L -n | grep -q '443'")
          node2.succeed("iptables -L -n | grep -q '443'")
          node3.succeed("iptables -L -n | grep -q '443'")

          # Wait for consul API to be ready on all nodes
          node1.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.10:8500/v1/status/leader)\"")
          node2.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.11:8500/v1/status/leader)\"")
          node3.wait_until_succeeds("test -n \"\$(curl -sk https://192.168.1.12:8500/v1/status/leader)\"")

          # Verify all nodes can see each other in consul
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/agent/members | grep -q 'node2'")
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/agent/members | grep -q 'node3'")

          # Verify traefik services are registered in consul on all nodes
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/traefik | grep -q 'traefik'")

          # Verify all 3 traefik services are registered (one per node)
          traefik_count = node1.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/traefik | grep -o 'ServiceID' | wc -l")
          assert "3" in traefik_count, f"Expected 3 traefik services, got: {traefik_count}"

          # Verify test-backend services are registered in consul
          node1.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/test-backend | grep -q 'test-backend'")
          backend_count = node1.succeed("curl -sk https://192.168.1.10:8500/v1/catalog/service/test-backend | grep -o 'ServiceID' | wc -l")
          assert "3" in backend_count, f"Expected 3 backend services, got: {backend_count}"

          # Verify traefik process is running on all nodes
          node1.succeed("pgrep -x traefik")
          node2.succeed("pgrep -x traefik")
          node3.succeed("pgrep -x traefik")

          # Verify backend services are running and responding locally
          node1.succeed("curl -s http://127.0.0.1:8080/ | grep -q 'Response from node1'")
          node2.succeed("curl -s http://127.0.0.1:8080/ | grep -q 'Response from node2'")
          node3.succeed("curl -s http://127.0.0.1:8080/ | grep -q 'Response from node3'")
        '';
      };
    };
}
