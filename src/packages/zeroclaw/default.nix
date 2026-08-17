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
          nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ pkgs.pkg-config ];

          buildInputs = (prev.buildInputs or [ ]) ++ [ pkgs.alsa-lib ];

          patches = (prev.patches or [ ]) ++ [
            ./bwrap-nixos.patch
            ./bwrap-workspace.patch
          ];

          cargoBuildFlags = (prev.cargoBuildFlags or [ ]) ++ [
            "--features"
            "voice-wake,channel-matrix,sandbox-bubblewrap,embedded-web"
          ];
        }
      );
  };
}
