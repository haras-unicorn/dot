{ self
, flake-utils
, nixpkgs
, ...
}:

let
  configs = flake-utils.lib.defaultSystems;

  wrap = path: name: system: inputs: nixpkgs.writeShellApplication {
    name = name;
    runtimeInputs = inputs;
    text = ''
      export SELF="${self}"
      export SYSTEM="${system}"

      "${path}" "$@"
    '';
  };
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
