{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-test = self.lib.test.mkTest pkgs {
        name = "Test test";
        nodes.machine =
          { pkgs, ... }:
          {
            environment.systemPackages = [ pkgs.hello ];
          };
        dot.test.commands.suffix = ''
          machine.succeed("hello")
        '';
      };
    };

  flake.tests = {
    test-test = {
      expr = true;
      expected = true;
    };
  };
}
