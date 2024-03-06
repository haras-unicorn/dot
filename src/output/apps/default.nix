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

          set +e
          if [[ "$SYSTEM" == "" ]]; then
            export SYSTEM="${system}"
          fi
          set -e

          printf "Running app '${name}' at '${path}' from '$SELF' for '$SYSTEM'.\n"

          "${path}" "$@"
        '';
      };
    in
    "${app}/bin/${name}";
in
builtins.foldl'
  (apps: system: apps // {
    "${system}" = {
      default = {
        type = "app";
        program = wrap "${self}/scripts/install" "install" system [ ];
      };
      image = {
        type = "app";
        program = wrap "${self}/scripts/image" "image" system [ ];
      };
    };
  })
  ({ })
  configs
