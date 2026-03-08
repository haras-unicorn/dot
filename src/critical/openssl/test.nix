{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openssl = self.lib.test.mkTest pkgs {
        name = "critical-openssl";
        nodes.machine = {
          dot.test.openssl.enable = true;
        };
        dot.test.commands.suffix = ''
          machine.succeed("test -d /etc/ssl/certs")
          machine.succeed("test -n \"$(ls -A /etc/ssl/certs/)\"")
          machine.log("OpenSSL module configuration verified successfully")
        '';
      };
    };
}
