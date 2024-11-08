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

          set +u
          if [[ "$SYSTEM" == "" ]]; then
            export SYSTEM="${system}"
          fi
          set -u

          printf \
            "Running app '%s' at '%s' from '%s' for '%s'.\n" \
            "${name}" \
            "${path}" \
            "$SELF" \
            "$SYSTEM"

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
        program = wrap "${self}/scripts/install.sh" "install" system [ ];
      };
      image = {
        type = "app";
        program = wrap "${self}/scripts/image.sh" "image" system [ ];
      };
    };
  })
  ({ })
  configs
