{ inputs, ... }:

{
  flake.homeModules.programs-opencode =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      hasNetwork = config.dot.hardware.network.enable;
    in
    lib.mkIf hasNetwork {
      programs.opencode.enable = true;
      programs.opencode.package =
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.oh-my-opencode;

      home.activation.setupOpenCodeAuth =
        let
          args = builtins.concatStringsSep " " (
            builtins.map ({ name, value }: ''--arg ${name} "$(cat ${value.homeKey})"'') (
              lib.attrsToList config.dot.openai.apis
            )
          );

          json = builtins.toJSON (
            lib.mapAttrs (name: _: {
              type = "api";
              key = "$" + name;
            }) config.dot.openai.apis
          );
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.jq}/bin/jq -n ${args} '${json}' \
            > "${config.xdg.dataHome}/opencode/auth.json"
          chmod 600 "${config.xdg.dataHome}/opencode/auth.json"
        '';
    };
}
