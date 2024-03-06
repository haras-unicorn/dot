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

          if [[ "$SYSTEM" == "" ]]; then
            export SYSTEM="${system}"
          fi

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
