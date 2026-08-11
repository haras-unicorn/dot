{ inputs, ... }:

{
  perSystem = { pkgs, ... }: {
    packages.zeroclaw =
      let
        system = pkgs.stdenv.hostPlatform.system;

        zeroclaw = inputs.llm-agents.packages.${system}.zeroclaw;
      in
      zeroclaw.overrideAttrs (
        final: prev: {
          patches = (prev.patches or [ ]) ++ [
            ./bwrap-nix-store.patch
          ];
          cargoBuildFlags = (prev.cargoBuildFlags or [ ]) ++ [
            "--all-features"
          ];
        }
      );
  };
}
