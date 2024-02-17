{ self
, flake-utils
, nixpkgs
, ...
}:

let
  configs = flake-utils.lib.defaultSystems;

  wrap = path: name: inputs: nixpkgs.writeShellApplication {
    name = name;
    runtimeInputs = inputs;
    text = ''
      export SELF="${self}"

      "${path}" "$@"
    '';
  };
in
builtins.foldl'
  (apps: system: apps // {
    "${system}".default = {
      type = "app";
      program = wrap "${self}/scripts/install" "install" [ ];
    };
  })
  ({ })
  configs
