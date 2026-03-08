{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-vault-disabled = self.lib.test.mkTest pkgs {
        name = "critical-vault-disabled";
        dot.test.disabledService.module = {
          imports = [
            self.nixosModules.critical-vault
          ];
        };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "vault.service";
        dot.test.disabledService.config = "/etc/vault";
      };

      checks.test-critical-vault-cluster = self.lib.test.mkTest pkgs {
        name = "critical-vault-cluster";
        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-vault
          ];

          dot.test.cockroachdb.enable = true;
          dot.vault.enable = true;
        };
        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_for_unit("vault.service", timeout=180)''
          (node: ''
            command_node.wait_until_succeeds("""
              curl http://${node.dot.host.ip}:8200/v1/sys/health | \
                grep -q 'initialized\":false'
            """, timeout=60)
          '')
          ''
            command_node.succeed("iptables -L -n | grep -q '8200'")
            command_node.succeed("iptables -L -n | grep -q '8201'")
          ''
          ''
            command_node.succeed("""
              dot-cockroach-root sql \
                --execute='SELECT COUNT(*) FROM vault.vault_kv_store'
            """)
          ''
        ];
      };
    };
}
