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

          # Shell
          nodePackages.bash-language-server
          shfmt
          shellcheck

          # Misc
          just
          nodePackages.prettier
          nodePackages.yaml-language-server
          nodePackages.vscode-json-languageserver
          marksman
          taplo
        ];
      };
    }
  ))
  ({ })
  (flake-utils.lib.defaultSystems)