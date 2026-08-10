{ selfLib, inputs, ... }:

{
  self.lib.dev.makePackages =
    pkgs:
    let
      flake-root = pkgs.writeShellApplication {
        name = "flake-root";
        text = ''
          current="$PWD"
          while [[ "$current" != "/" ]]; do
            if [[ -f "$current/flake.nix" ]]; then
              echo "$current"
              exit 0
            fi
            current="$(dirname "$current")"
          done
          echo "no flake.nix found" >&2
          exit 1
        '';
      };

      packages = with pkgs; [
        nil
        nixfmt
        nixos-facter

        github-cli
        nushell
        helix
        opencode
        fd

        prettier
        yaml-language-server
        vscode-langservers-extracted
        markdownlint-cli
        markdown-link-check
        marksman
        taplo
        cspell

        flake-root
      ];

      cli =
        let
          path = builtins.concatStringsSep "\n    " (builtins.map (input: "`${input}/bin`") packages);

          src = ./cli.nu;
          bin = "dev";

          wrapped = pkgs.writeText "cli" ''
            #!${pkgs.lib.getExe pkgs.nushell}

            export-env {
              $env.FILE_NAME = "${bin}"
              $env.PATH ++= [
                ${path}
              ]
            }

            ${builtins.readFile src}
          '';
        in
        pkgs.runCommand "cli"
          {
            nativeBuildInputs = [ pkgs.nushell ];
            meta.mainProgram = "${bin}";
          }
          ''
            nu --commands "nu-check --debug ${wrapped}"
            mkdir -p $out/bin
            cp ${wrapped} $out/bin/${bin}
            chmod +x $out/bin/${bin}
          '';
    in
    packages ++ [ cli ];

  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      # FATE llama.cpp — same src/hash as src/modules/ai/llama-cpp.nix, so
      # `nix build .#llama-cpp-fate` tests exactly what the machine builds.
      # The CUDA-enabled nixpkgs instance mirrors the machine's nixpkgs
      # config (see src/modules/hardware/nvidia/default.nix).
      fatePkgs = import inputs.nixpkgs {
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
        inherit system;
      };
      fateSrc = fatePkgs.fetchFromGitHub {
        owner = "ongunm";
        repo = "llama-moe-cache";
        rev = "77c8767d26bd6285b2fe351c58143ee4d6b72fa6";
        hash = "sha256-5sAd5aSmC926ND1IZY5FtkAjRcJCvSzlJHTXJk+jjj8=";
      };
      shell = pkgs.mkShell {
        packages = selfLib.dev.makePackages pkgs;
      };
    in
    {
      devShells.dev = shell;
      devShells.default = shell;

      packages.llama-cpp-fate = (fatePkgs.callPackage "${fateSrc}/.devops/nix/scope.nix" { }).llama-cpp;
    };
}
