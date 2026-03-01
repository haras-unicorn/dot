{ inputs, config, ... }:

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
        hostname = "${config.dot.host.name}-${pkgs.stdenv.hostPlatform.system}";
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
      checks.test-critical-comin = config.flake.lib.test.mkTest pkgs {
        name = "critical-comin";
        nodes.machine = {
          imports = [
            config.flake.nixosModules.critical-comin
          ];
          options.dot.host.name = pkgs.lib.mkOption {
            type = pkgs.lib.types.str;
            default = "testhost";
          };
        };
        script = ''
          start_all()
          machine.succeed("systemctl is-enabled comin.service")
          machine.succeed("which comin")
        '';
      };
    };
}
