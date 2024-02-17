{ self
, flake-utils
, nixpkgs
, ...
}:

let
  configs = flake-utils.lib.defaultSystems;

  wrap = path: name: system: inputs:
    let
      app = nixpkgs.legacyPackages.${system}.writeShellApplication {
        name = name;
        runtimeInputs = inputs;
        text = ''
          export SELF="${self}"
          export SYSTEM="${system}"

          "${path}" "$@"
        '';
      };
    in
    "${app}/name";
in
builtins.foldl'
  (apps: system: apps // {
    "${system}".default = {
      type = "app";
      program = wrap "${self}/scripts/install" "install" system [ ];
    };
  })
  ({ })
  configs