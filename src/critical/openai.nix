{ self, ... }:

let
  apis = [
    "deepseek"
    "openai"
    "openrouter"
  ];
in
{
  flake.nixosModules.critical-openai =
    { config, lib, ... }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      configApi = name: {
        dot.openai = {
          apis = {
            ${name} = {
              secret = "${name}-api-key";
              systemKey = config.sops.secrets."${name}-api-key".path;
              homeKey = config.sops.secrets."home-${name}-api-key".path;
            };
          };
        };

        sops.secrets."home-${name}-api-key" = {
          key = "${name}-api-key";
          owner = config.dot.host.user;
          group = config.dot.host.user;
          mode = "0400";
        };

        sops.secrets."${name}-api-key" = {
          mode = "0400";
        };

        cryl.sops.keys = [
          "${name}-api-key"
        ];
        cryl.specification.imports = [
          {
            importer = "vault-file";
            arguments = {
              path = self.lib.vault.shared;
              file = "${name}-api-key";
              allow_fail = false;
            };
          }
        ];

      };
    in
    lib.mkIf hasNetwork (lib.mkMerge (builtins.map configApi apis));

  flake.homeModules.critical-openai =
    { osConfig, ... }:
    {
      dot.openai = osConfig.dot.openai;
    };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, ... }:
    {
      checks.test-critical-openai = self.lib.test.mkTest pkgs {
        name = "critical-openai";

        dot.test.cryl.shared.specification.generations =
          let
            generateApiKey = name: {
              generator = "text";
              arguments = {
                name = "${name}-api-key";
                text = "${name}-test";
              };
            };
          in
          builtins.map generateApiKey apis;

        nodes.machine = {
          imports = [ self.nixosModules.critical-openai ];
        };

        dot.test.commands.suffix =
          let
            checkApiKeys = name: ''
              machine.succeed("""
                [[ "$(cat /run/secrets/${name}-api-key)" == "${name}-test" ]]
              """)
              machine.succeed("""
                [[ "$(cat /run/secrets/home-${name}-api-key)" == "${name}-test" ]]
              """)
              machine.succeed("""
                [[ "$(stat -c %U /run/secrets/home-${name}-api-key)" != "root" ]]
              """)
            '';

            checkCommands = builtins.concatStringsSep "\n" (builtins.map checkApiKeys apis);
          in
          ''
            machine.wait_for_unit("multi-user.target")
            ${checkCommands}
          '';
      };
    };
}
