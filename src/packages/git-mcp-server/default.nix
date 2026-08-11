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

      # NOTE: fetch git because fetchFromGitHub doesn't download tsconfig.json
      src = pkgs.fetchgit {
        url = "https://github.com/cyanheads/git-mcp-server";
        # NOTE: v2.15.1
        rev = "31dd1918500a51129f0a086ed3471527961c7572";
        hash = "sha256-zJdkkEbmXMHHnj1ISMTeUVpARL7t5RVhOnm1PIfjOqg=";
      };
    in
    {
      packages.git-mcp-server = bun2nix.mkDerivation {
        inherit src;

        packageJson = "${src}/package.json";

        bunDeps = bun2nix.fetchBunDeps {
          bunNix = ./bun.nix.lock;
        };

        nativeBuildInputs = [
          pkgs.makeWrapper
        ];

        dontRunLifecycleScripts = true;

        buildPhase = ''
          bun run build
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/lib/git-mcp-server $out/bin
          cp -r dist $out/lib/git-mcp-server/dist
          cp -r node_modules $out/lib/git-mcp-server/node_modules

          makeWrapper ${lib.getExe pkgs.bun} $out/bin/git-mcp-server \
            --argv0 git-mcp-server \
            --add-flags "$out/lib/git-mcp-server/dist/index.js"

          runHook postInstall
        '';
      };
    };
}
