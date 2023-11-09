{ self, nixpkgs, flake-utils, ... }:

let
{
  systems = flake-utils.defaultSystems; 
}
in
builtins.foldl'
  (devShells: system:
  devShells // {
    "${system}".default = nixpkgs.mkShell {
      packages = with nixpkgs; [ nil nixpkgs-fmt ];
    }
  })
  { }
  systems
