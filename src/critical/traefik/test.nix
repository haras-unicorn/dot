{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-traefik-disabled = self.lib.test.mkTest pkgs {
        name = "critical-traefik-disabled";
        dot.test.disabledService.module = {
          imports = [
            self.nixosModules.critical-traefik
            self.nixosModules.critical-consul
            self.nixosModules.critical-openssl
          ];
        };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "traefik.service";
        dot.test.disabledService.config = "/etc/traefik";
      };

      checks.test-critical-traefik-cluster =
        let
          backendPort = 8080;
          backendPortString = builtins.toString backendPort;

          amount = 3;
          amountString = builtins.toString amount;
        in
        self.lib.test.mkTest pkgs {
          name = "critical-traefik-cluster";
          dot.test.clusters.node.amount = amount;
          dot.test.clusters.node.module =
            {
              config,
              lib,
              pkgs,
              ...
            }:
            let
              backendScript = pkgs.writeText "test-backend-script" ''
                import http.server
                import socketserver
                import sys

                PORT = ${backendPortString}
                NODE_NAME = '${config.dot.host.name}'

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

                with socketserver.TCPServer(('${config.dot.host.ip}', PORT), Handler) as httpd:
                    httpd.serve_forever()
              '';

              backendApp = pkgs.writeShellApplication {
                name = "test-backend";
                runtimeInputs = [ pkgs.python3 ];
                text = ''python3 "${backendScript}"'';
              };
            in
            {
              imports = [
                self.nixosModules.critical-traefik
                self.nixosModules.critical-consul
                self.nixosModules.critical-openssl
              ];

              dot.traefik.enable = true;
              dot.consul.enable = true;

              dot.services = [
                {
                  port = backendPort;
                  name = "test-backend";
                  health = "http:///health";
                }
              ];

              systemd.services.test-backend = {
                description = "Test backend service for traefik load balancing";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];
                serviceConfig = {
                  Type = "simple";
                  ExecStart = lib.getExe backendApp;
                  Restart = "always";
                };
              };
            };
          dot.test.commands.enable = true;
          dot.test.commands.perNode = [
            ''command_node.wait_for_unit("network-online.target")''
            ''command_node.wait_for_unit("test-backend.service")''
            ''command_node.wait_for_unit("consul.service")''
            ''command_node.wait_for_unit("traefik.service")''
            ''command_node.succeed("iptables -L -n | grep -q '443'")''
            (node: ''
              command_node.wait_until_succeeds("""
                test -n "$(curl -sk https://${node.dot.host.ip}:8500/v1/status/leader)"
              """)
            '')
            (
              { node, nodea, ... }:
              builtins.map (other: ''
                command_node.wait_until_succeeds("""
                  curl -sk https://${node.dot.host.ip}:8500/v1/agent/members | \
                    grep -q '${other.dot.host.name}'
                """)
              '') nodea
            )
            (node: ''
              command_node.wait_until_succeeds("""
                curl -sk https://${node.dot.host.ip}:8500/v1/catalog/service/traefik | \
                  grep -q 'traefik'
              """)
            '')
            (node: ''
              command_node.wait_until_succeeds("""
                count=$(curl -sk https://${node.dot.host.ip}:8500/v1/catalog/service/traefik | \
                  jq length)
                [ "$count" -eq "${amountString}" ]
              """)
            '')
            (node: ''
              command_node.wait_until_succeeds("""
                count=$(curl -sk https://${node.dot.host.ip}:8500/v1/catalog/service/test-backend | \
                  jq length)
                [ "$count" -eq "${amountString}" ]
              """)
            '')
            ''command_node.succeed("pgrep -x traefik")''
            (node: ''
              command_node.succeed("""
                curl -s http://${node.dot.host.ip}:${backendPortString}/ | \
                  grep -q 'Response from ${node.dot.host.name}'
              """)
            '')
          ];
        };
    };
}
