{ inputs, ... }:

{
  self.overlays.overlays.zeroclaw = {
    flake = true;

    value = final: _prev: {
      zeroclaw =
        let
          system = final.stdenv.hostPlatform.system;

          zeroclaw = inputs.llm-agents.packages.${system}.zeroclaw;
        in
        zeroclaw.overrideAttrs (
          _final: prev: {
            nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ final.pkg-config ];

            buildInputs = (prev.buildInputs or [ ]) ++ [ final.alsa-lib ];

            patches = (prev.patches or [ ]) ++ [
              ./bwrap-nixos.patch
              ./bwrap-workspace.patch
              ./remove-api-error-limit.patch
            ];

            cargoBuildFlags = (prev.cargoBuildFlags or [ ]) ++ [
              "--features"
              "voice-wake,channel-matrix,sandbox-bubblewrap,embedded-web"
            ];
          }
        );
    };
  };
}
