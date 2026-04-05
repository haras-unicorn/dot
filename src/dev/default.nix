{ self, inputs, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, system, ... }:
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

      external =
        with pkgs;
        [
          # Nix
          nil
          nixfmt-rfc-style
          nix-unit

          # Scripts
          nushell
          gum
          fzf
          fd

          # Misc
          nodePackages.prettier
          nodePackages.yaml-language-server
          nodePackages.vscode-langservers-extracted
          markdownlint-cli
          nodePackages.markdown-link-check
          marksman
          taplo

          # Tools
          flake-root
          nodePackages.cspell
          nixos-generators
          inputs.cryl.packages.${system}.default
          nebula
          openssh
          sshpass
          vault
          vault-medusa
          postgresql
          mariadb
          s3cmd
          deploy-rs
          zstd
        ]
        ++ lib.optionals (system == "x86_64-linux") [
          libguestfs-with-appliance
        ];

      cli = self.lib.cli.mkCli pkgs {
        name = "dev-dot";
        runtimeInputs = external;
        text = builtins.readFile ./dev.nu;
      };

      devShell = pkgs.mkShell {
        packages = external ++ [ cli ];
      };
    in
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      devShells.dev = devShell;
      devShells.default = devShell;
    };
}
