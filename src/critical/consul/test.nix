{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-consul-disabled = self.lib.test.mkTest pkgs {
        name = "critical-consul-disabled";
        dot.test.disabledService.module = {
          imports = [
            self.nixosModules.critical-consul
            self.nixosModules.critical-openssl
          ];
        };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "consul.service";
        dot.test.disabledService.config = "/etc/consul";
      };

      checks.test-critical-consul-enabled = self.lib.test.mkTest pkgs {
        name = "critical-consul-enabled";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-consul
            self.nixosModules.critical-openssl
          ];

          dot.consul.enable = true;
          dot.host.interface = "dot";
        };
        testScript =
          { nodes, ... }:
          ''
            start_all()

            machine.wait_for_unit("consul.service")
            machine.succeed("which consul")
            machine.succeed("systemctl is-enabled consul.service")
            machine.succeed("test -d /etc/consul")
            machine.succeed("test -d /etc/consul/certs")

            machine.wait_until_succeeds("""
              test -n "$(curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/status/leader)"
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/status/leader | \
                grep -Eq '[0-9]+.[0-9]+.[0-9]+.[0-9]+:[0-9]+'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/agent/self | \
                grep -q 'machine'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/catalog/datacenters | \
                grep -q 'dot'
            """)

            machine.succeed("iptables -L -n | grep -q '8500'")
            machine.succeed("iptables -L -n | grep -q '8300'")
            machine.succeed("iptables -L -n | grep -q '8301'")
            machine.succeed("iptables -L -n | grep -q '8302'")
            machine.succeed("iptables -L -n | grep -q '8503'")

            machine.fail("""
              grep -r 'disable-dnssec-dot' /etc/NetworkManager/dispatcher.d/ 2>/dev/null
            """)
          '';
      };

      checks.test-critical-consul-services = self.lib.test.mkTest pkgs {
        name = "critical-consul-services";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-consul
            self.nixosModules.critical-openssl
          ];

          dot.consul.enable = true;

          dot.services = [
            {
              name = "test-service";
              port = 8080;
              health = "http:///health";
            }
          ];
        };
        testScript =
          { nodes, ... }:
          ''
            start_all()

            machine.wait_for_unit("consul.service")
            machine.succeed("which consul")
            machine.succeed("systemctl is-enabled consul.service")

            machine.wait_until_succeeds("""
              test -n "$(curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/status/leader)"
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/status/leader | \
                grep -Eq '[0-9]+.[0-9]+.[0-9]+.[0-9]+:[0-9]+'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/catalog/service/test-service | \
                grep -q 'test-service'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/catalog/service/test-service | \
                grep -q 'test'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/catalog/service/test-service | \
                grep -q 'dot'
            """)
            machine.wait_until_succeeds("""
              curl -sk https://${nodes.machine.dot.host.ip}:8500/v1/catalog/service/consul-ui | \
                grep -q 'consul-ui'
            """)
          '';
      };

      checks.test-critical-consul-cluster = self.lib.test.mkTest pkgs {
        name = "critical-consul-cluster";
        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-consul
            self.nixosModules.critical-openssl
          ];
          dot.consul.enable = true;
        };
        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_for_unit("network-online.target")''
          ''command_node.wait_for_unit("consul.service")''
          ''command_node.succeed("systemctl is-enabled consul.service")''
          ''command_node.succeed("which consul")''
          (node: ''
            command_node.succeed("grep '${node.dot.host.name}' /etc/consul.json")
          '')
          (node: ''
            command_node.succeed("grep -q '${node.dot.host.ip}' /etc/consul.json")
          '')
          (
            { nodea, ... }:
            builtins.map (other: ''
              command_node.succeed("grep -q '${other.dot.host.ip}' /etc/consul.json")
            '') nodea
          )
          ''
            command_node.succeed("iptables -L -n | grep -q '8500'")
            command_node.succeed("iptables -L -n | grep -q '8300'")
            command_node.succeed("iptables -L -n | grep -q '8301'")
            command_node.succeed("iptables -L -n | grep -q '8302'")
          ''
          (node: ''
            command_node.wait_until_succeeds("""
              test -n "$(curl -sk https://${node.dot.host.ip}:8500/v1/status/leader)"
            """)
          '')
          (node: ''
            command_node.wait_until_succeeds("""
              curl -sk https://${node.dot.host.ip}:8500/v1/status/leader | \
                grep -Eq '[0-9]+.[0-9]+.[0-9]+.[0-9]+:[0-9]+'
            """)
          '')
          (
            { node, nodea, ... }:
            builtins.map (other: ''
              command_node.wait_until_succeeds("""
                curl -sk https://${node.dot.host.ip}:8500/v1/agent/members | \
                  grep -Eq '${other.dot.host.name}'
              """)
            '') nodea
          )
        ];
        dot.test.commands.suffix = nodes: ''
          leader_output = node1.succeed("curl -sk https://${nodes.node1.dot.host.ip}:8500/v1/status/leader")
          assert leader_output.strip() != '""', "Cluster should have elected a leader"
          assert "8300" in leader_output, "Leader should be listening on port 8300"
        '';
      };
    };
}
