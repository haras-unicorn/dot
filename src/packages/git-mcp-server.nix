{
  perSystem =
    { lib, pkgs, ... }:
    let
      # NOTE: version 2.1.2
      bun2nix = builtins.getFlake (
        "github:nix-community/bun2nix/0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729"
        + "?narHash=sha256-9BMxlTxCCDAeoNLtb1a/st7udtTIJep%2BwpUzquA29VU%3D"
      );
    in
    {
      packages.git-mcp-server = pkgs.stdenv.mkDerivation (final: {
        pname = "git-mcp-server";
        version = "2.15.1";

        src = pkgs.fetchFromGitHub {
          owner = "cyanheads";
          repo = "git-mcp-server";
          rev = "v${final.version}";
          hash = "sha256-CzKb4HRVrf/XyldYm69KJWn6cIpVAfz9Vg7q2j6SBdc=";
        };

        nativeBuildInputs = [
          bun2nix.lib.hook
          pkgs.bun
        ];

        bunDeps = bun2nix.lib.fetchBunDeps {
          bunNix = ./git-mcp-server/bun.nix;
        };

        # The hook provides bunInstall/bunBuild/bunInstallPhase defaults for
        # `bun build --compile` flows; we run `bun build` ourselves and install
        # dist/ by hand, and skip the lifecycle (husky prepare) install.
        dontUseBunBuild = true;
        dontUseBunInstall = true;
        dontRunLifecycleScripts = true;

        # Pin every dependency to the exact version vendored in bun.nix. bun's
        # offline resolver refuses semver ranges (^/~) when only one version is
        # present in the store, so collapse them to exact pins.
        postPatch = ''
          sed -i 's/: "\^/: "/g; s/: "~/: "/g' package.json bun.lock
        '';

        buildPhase = ''
          runHook preBuild
          bun build ./src/index.ts --outdir ./dist --target node \
            --external pino --external pino-pretty
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mkdir -p $out/lib/git-mcp-server $out/bin
          cp -r dist $out/lib/git-mcp-server/dist
          bun install --production --frozen-lockfile --offline --ignore-scripts
          cp -r node_modules $out/lib/git-mcp-server/node_modules
          cat > $out/bin/git-mcp-server <<EOF
          #!${pkgs.stdenv.shell}
          exec ${lib.getExe pkgs.bun} "$out/lib/git-mcp-server/dist/index.js" "\$@"
          EOF
          chmod +x $out/bin/git-mcp-server
          runHook postInstall
        '';

        meta = {
          description = "Secure and scalable Git MCP server for AI agents (cyanheads)";
          homepage = "https://github.com/cyanheads/git-mcp-server";
          license = lib.licenses.asl20;
          mainProgram = "git-mcp-server";
          platforms = lib.platforms.unix;
        };
      });
    };
}
