{ nixpkgs, flake-utils, ... }:

builtins.foldl'
  (devShells: system:
  devShells // (
    let
      pkgs = nixpkgs.legacyPackages."${system}";
    in
    {
      "${system}".default = pkgs.mkShell {
        packages = with pkgs; [ nil nixpkgs-fmt ];
      };
    }
  ))
  ({ })
  (flake-utils.lib.defaultSystems)
