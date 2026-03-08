{ self, ... }:

{
  flake.nixosModules.critical-journald = {
    services.journald.extraConfig = ''
      SystemMaxUse=750M
      SystemMaxFileSize=100M
      MaxRetentionSec=1month
    '';
  };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-journald = self.lib.test.mkTest pkgs {
        name = "critical-journald";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-journald
          ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("grep 'SystemMaxUse=750M' /etc/systemd/journald.conf")
          machine.succeed("grep 'SystemMaxFileSize=100M' /etc/systemd/journald.conf")
          machine.succeed("grep 'MaxRetentionSec=1month' /etc/systemd/journald.conf")
        '';
      };
    };
}
