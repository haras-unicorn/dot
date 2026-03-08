{ inputs, self, ... }:

{
  flake.nixosModules.critical-comin =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.comin.nixosModules.comin
      ];

      services.comin = {
        enable = true;
        hostname = config.dot.host.name;
        remotes = [
          {
            name = "origin";
            url = "https://github.com/haras-unicorn/dot";
            branches.main.name = "main";
          }
        ];
      };
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-comin = self.lib.test.mkTest pkgs {
        name = "critical-comin";
        nodes.machine = {
          imports = [
            self.nixosModules.critical-comin
          ];
        };
        dot.test.commands.suffix = ''
          machine.succeed("systemctl is-enabled comin.service")
          machine.succeed("which comin")
        '';
      };
    };
}
