{ unstablePkgs, ... }:

{
  homeManagerModule = {
    home.packages = [
      (unstablePkgs.mistral-rs.overrideAttrs (
        final: prev: {
          buildFeatures = prev.buildFeatures ++ [ "flash-attn" ];
        }
      ))
    ];
  };
}
