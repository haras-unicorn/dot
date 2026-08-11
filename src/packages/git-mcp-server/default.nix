{
  perSystem =
    { lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;

      # NOTE: version 2.1.2
      bun2nixFlake = builtins.getFlake (
        "github:nix-community/bun2nix/0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729"
        + "?narHash=sha256-9BMxlTxCCDAeoNLtb1a/st7udtTIJep%2BwpUzquA29VU%3D"
      );

      bun2nix = bun2nixFlake.packages.${system}.default;

      src = pkgs.fetchFromGitHub {
        owner = "cyanheads";
        repo = "git-mcp-server";
        # NOTE: v2.15.1
        rev = "31dd1918500a51129f0a086ed3471527961c7572";
        hash = "sha256-CzKb4HRVrf/XyldYm69KJWn6cIpVAfz9Vg7q2j6SBdc=";
      };
    in
    {
      packages.git-mcp-server = bun2nix.writeBunApplication (final: {
        inherit src;

        packageJson = "${src}/package.json";

        bunDeps = bun2nix.fetchBunDeps {
          bunNix = ./bun.nix.lock;
        };

        dontRunLifecycleScripts = true;

        buildPhase = ''
          cp ${src}/tsconfig.json .
          bun run build
        '';

        startScript = ''
          bun run start
        '';
      });
    };
}
