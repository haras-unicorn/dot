{ inputs, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];
  perSystem =
    { pkgs, system, ... }:
    let
      devShell = pkgs.mkShell {
        packages =
          with pkgs;
          [
            # Nix
            nil
            nixfmt-rfc-style
            nix-unit

            # Scripts
            just
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
