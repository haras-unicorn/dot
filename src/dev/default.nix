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
      shell = pkgs.mkShell {
        packages = selfLib.dev.makePackages pkgs;
      };
    in
    {
      devShells.dev = shell;
      devShells.default = shell;
    };
}
