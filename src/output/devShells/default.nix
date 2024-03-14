{ nixpkgs, flake-utils, ... }:

builtins.foldl'
  (devShells: system:
  devShells // (
    let
      pkgs = nixpkgs.legacyPackages."${system}";
    in
    {
      "${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          # Nix
          nil
          nixpkgs-fmt

          # Scripts
          nodePackages.bash-language-server
          shfmt
          shellcheck
          yapf

          # Misc
          nodePackages.prettier
          nodePackages.yaml-language-server
          nodePackages.vscode-json-languageserver
          marksman
          taplo
          html-tidy

          # Tools
          just
          openssl
          openvpn
          openssh
          age
          sops
        ];
      };
    }
  ))
  ({ })
  (flake-utils.lib.defaultSystems)
