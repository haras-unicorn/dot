{ inputs, ... }:

{
  self.lib.deprecated.homeModules.crush =
    {
      pkgs,
      config,
      osConfig,
      lib,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;
    in
    lib.mkIf hardware.editor {
      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.crush
      ];

      xdg.configFile."crush/crush.json".source = ./crush.json;
    };
}
