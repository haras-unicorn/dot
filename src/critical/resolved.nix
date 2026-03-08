{ self, ... }:

# TODO: dnssec and dnsovertls

{
  flake.nixosModules.critical-resolved =
    {
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    {
      config = lib.mkIf hasNetwork {
        networking.networkmanager.dns = "systemd-resolved";
        networking.nameservers = lib.mkBefore [
          # Cloudflare
          "1.1.1.1"
          "1.0.0.1"
          # Google
          "8.8.8.8"
          "8.8.4.4"
        ];

        services.resolved.enable = true;
        services.resolved.fallbackDns = [ ];
        services.resolved.dnssec = "false";
        services.resolved.dnsovertls = "false";
        services.resolved.llmnr = "false";
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-resolved = self.lib.test.mkTest pkgs {
        name = "critical-resolved";
        dot.test.dns.enable = true;
        dot.test.dns.zones = {
          "test.dot" = {
            "localhost.test.dot" = "127.0.0.1";
          };
        };
        nodes.machine = {
          imports = [
            self.nixosModules.critical-resolved
          ];
        };
        dot.test.commands.suffix =
          { nodes, ... }:
          ''
            machine.succeed("systemctl is-enabled systemd-resolved.service")
            machine.succeed("grep 'DNS=${nodes.dns.dot.host.ip}' /etc/systemd/resolved.conf")
            machine.succeed("grep 'DNSSEC=false' /etc/systemd/resolved.conf")
            machine.succeed("grep 'DNSOverTLS=false' /etc/systemd/resolved.conf")
            machine.succeed("grep 'LLMNR=false' /etc/systemd/resolved.conf")
            machine.succeed("resolvectl query localhost.test.dot | grep -q '127.0.0.1'")
            machine.succeed("dig @${nodes.dns.dot.host.ip} localhost.test.dot | grep -q '127.0.0.1'")
            machine.succeed("getent hosts localhost.test.dot | grep -q '127.0.0.1'")
          '';
      };
    };
}
