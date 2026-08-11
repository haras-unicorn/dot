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
    in
    {
      packages.git-mcp-server = bun2nix.mkDerivation (final: {
        pname = "git-mcp-server";
        version = "2.15.1";

        src = pkgs.fetchFromGitHub {
          owner = "cyanheads";
          repo = "git-mcp-server";
          rev = "v${final.version}";
          hash = "sha256-CzKb4HRVrf/XyldYm69KJWn6cIpVAfz9Vg7q2j6SBdc=";
        };

        bunDeps = bun2nix.fetchBunDeps {
          bunNix = ./bun.nix.lock;
        };

        module = "src/index.ts";
      });
    };
}
