{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-vaultwarden-disabled = self.lib.test.mkTest pkgs {
        name = "critical-vaultwarden-disabled";
        dot.test.disabledService.module = {
          imports = [
            self.nixosModules.critical-vaultwarden
          ];
        };
        dot.test.disabledService.enable = true;
        dot.test.disabledService.name = "vaultwarden.service";
        dot.test.disabledService.config = "/etc/vaultwarden";
      };

      checks.test-critical-vaultwarden-cluster = self.lib.test.mkTest pkgs {
        name = "critical-vaultwarden-cluster";

        dot.test.clusters.node.amount = 3;
        dot.test.clusters.node.module = {
          imports = [
            self.nixosModules.critical-vaultwarden
          ];

          dot.test.cockroachdb.enable = true;
          dot.vaultwarden.enable = true;
        };

        dot.test.commands.enable = true;
        dot.test.commands.perNode = [
          ''command_node.wait_for_unit("vaultwarden.service", timeout=180)''
          ''command_node.wait_until_succeeds("curl -f http://192.168.1.10:8222/alive", timeout=60)''
          ''command_node.succeed("iptables -L -n | grep -q '8222'")''
          ''
            command_node.succeed("""
              dot-cockroach-root sql \
                --execute="SELECT datname FROM pg_database WHERE datname = 'vaultwarden'"
            """)
          ''
        ];
      };
    };
}
