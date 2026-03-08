{ self, ... }:

{
  flake.nixosModules.critical-resolved =
    {
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
      nameservers = [
        # Cloudflare
        "1.1.1.1"
        "1.0.0.1"
        # Google
        "8.8.8.8"
        "8.8.4.4"
      ];
    in
    {
      config = lib.mkIf hasNetwork {
        networking.networkmanager.dns = "systemd-resolved";
        networking.nameservers = nameservers;

        services.resolved.enable = true;
        services.resolved.fallbackDns = [ ];
        services.resolved.dnssec = "allow-downgrade";
        services.resolved.dnsovertls = "opportunistic";
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
        nodes.machine = {
          imports = [
            self.nixosModules.critical-resolved
          ];
        };
        testScript = ''
          start_all()
          machine.succeed("systemctl is-enabled systemd-resolved.service")
          machine.succeed("grep 'DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4' /etc/systemd/resolved.conf")
          machine.succeed("grep 'DNSSEC=allow-downgrade' /etc/systemd/resolved.conf")
          machine.succeed("grep 'DNSOverTLS=opportunistic' /etc/systemd/resolved.conf")
          machine.succeed("grep 'LLMNR=false' /etc/systemd/resolved.conf")
        '';
      };
    };
}
