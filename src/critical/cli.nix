{ self, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { lib, pkgs, ... }:
    let
      name = "dot";

      cli = self.lib.cli.mkCli pkgs { inherit name; };

      cliApp = {
        type = "app";
        program = lib.getExe cli;
        meta.description = "${name} CLI";
      };
    in
    {
      packages = {
        inherit cli;
        default = cli;
      };

      apps = {
        cli = cliApp;
        default = cliApp;
      };

      checks.test-critical-cli = self.lib.test.mkTest pkgs {
        name = "critcal-cli";
        nodes.machine = {
          imports = [ self.nixosModules.critical-cli ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("${name}")
        '';
      };
    };

  flake.nixosModules.critical-cli =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.cli
      ];
    };

  flake.homeModules.critical-cli =
    { pkgs, ... }:
    {
      home.packages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.cli
      ];
    };
}
