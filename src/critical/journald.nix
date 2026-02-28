{ config, ... }:

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
      checks.test-critical-journald = config.flake.lib.test.mkTest pkgs {
        name = "critical-journald";
        nodes.test = {
          imports = [ config.flake.nixosModules.critical-journald ];
        };
        script = ''
          start_all()
          test.succeed("grep 'SystemMaxUse=750M' /etc/systemd/journald.conf")
          test.succeed("grep 'SystemMaxFileSize=100M' /etc/systemd/journald.conf")
          test.succeed("grep 'MaxRetentionSec=1month' /etc/systemd/journald.conf")
        '';
      };
    };
}
