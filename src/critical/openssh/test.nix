{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openssh = self.lib.test.mkTest pkgs {
        name = "critical-openssh";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-openssh
          ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("systemctl is-enabled sshd.service")
          machine.succeed("grep 'PermitRootLogin no' /etc/ssh/sshd_config")
          machine.succeed("grep 'PasswordAuthentication no' /etc/ssh/sshd_config")
          machine.succeed("grep 'KbdInteractiveAuthentication no' /etc/ssh/sshd_config")
        '';
      };

      checks.test-critical-openssh-cli-command = self.lib.test.mkTest pkgs {
        name = "critical-openssh-cli-command";
        dot.test.clusters.node.amount = 2;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-openssh
            self.nixosModules.critical-cli
          ];
        };
        dot.test.commands.perNode = [
          ''
            command_node.wait_for_unit("sshd.service")
          ''
        ];
        dot.test.commands.suffix =
          { nodes, lib, ... }:
          ''
            node1.succeed("""
              su - ${lib.escapeShellArg nodes.node1.dot.host.user} \
                -c 'dot ssh command --host node1 cat /etc/hostname 2>/dev/null' | \
                grep -q node1
            """)
            node2.succeed("""
              su - ${lib.escapeShellArg nodes.node2.dot.host.user} \
                -c 'dot ssh command --host node2 cat /etc/hostname 2>/dev/null' | \
                grep -q node2
            """)
          '';
      };

      checks.test-critical-openssh-cli-copy = self.lib.test.mkTest pkgs {
        name = "critical-openssh-cli-copy";
        dot.test.clusters.node.amount = 2;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-openssh
            self.nixosModules.critical-cli
          ];
        };
        dot.test.commands.perNode = [
          ''
            command_node.wait_for_unit("sshd.service")
          ''
        ];
        dot.test.commands.suffix =
          { nodes, lib, ... }:
          ''
            node1.succeed("""
              su - ${lib.escapeShellArg nodes.node1.dot.host.user} \
                -c "dot ssh copy node2:/etc/hostname ${
                  lib.escapeShellArg (nodes.node1.dot.host.home + "/hostname")
                } 2>/dev/null"
            """)
            node1.succeed("""
              cat ${lib.escapeShellArg (nodes.node1.dot.host.home + "/hostname")} | \
                grep -q node2
            """)
            node2.succeed("""
              su - ${lib.escapeShellArg nodes.node2.dot.host.user} \
                -c "dot ssh copy node1:/etc/hostname ${
                  lib.escapeShellArg (nodes.node2.dot.host.home + "/hostname")
                } 2>/dev/null"
            """)
            node2.succeed("""
              cat ${lib.escapeShellArg (nodes.node2.dot.host.home + "/hostname")} | \
                grep -q node1
            """)
          '';
      };
    };
}
