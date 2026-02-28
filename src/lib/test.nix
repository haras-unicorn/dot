{ config, ... }:

{
  libAttrs.test.mkTest =
    pkgs:
    {
      name,
      nodes,
      script,
    }:
    pkgs.testers.runNixOSTest {
      inherit name nodes;
      testScript = script;
      sshBackdoor.enable = true;
      defaults = {
        # Workaround for nixpkgs gzip/install-info issue
        documentation.info.enable = false;
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-test = config.flake.lib.test.mkTest pkgs {
        name = "Test test";
        nodes.test =
          { pkgs, ... }:
          {
            environment.systemPackages = [ pkgs.hello ];
          };
        script = ''
          start_all()
          test.succeed("hello")
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
