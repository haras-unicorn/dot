{
  flake.homeModules.programs-mistral-rs =
    { unstablePkgs, ... }:
    {
      home.packages = [
        (unstablePkgs.mistral-rs.overrideAttrs (
          final: prev: {
            buildFeatures = prev.buildFeatures ++ [ "flash-attn" ];
          }
        ))
      ];
    };
}
