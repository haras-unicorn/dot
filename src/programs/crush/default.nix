{ inputs, ... }:

{
  flake.homeModules.programs-crush =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;

      exports = builtins.concatStringsSep "\n" (
        builtins.map (
          { name, value, ... }:
          ''
            # shellcheck disable=SC2155
            export ${lib.toUpper name}_API_KEY="cat "${value.homeKey}")"
          ''
        ) (lib.attrsToList config.dot.openai.apis)
      );

      crush = pkgs.writeShellApplication {
        name = "crush";
        runtimeInputs = [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush
        ];
        text = ''
          ${exports}
          crush "$@"
        '';
      };
    in
    lib.mkIf hasNetwork {
      home.packages = [
        crush
      ];

      xdg.configFile."crush/crush.json".source = ./crush.json;
    };
}
