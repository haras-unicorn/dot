{ self
, flake-utils
, ...
}:

let
  configs = flake-utils.lib.defaultSystems;
in
builtins.foldl'
  (apps: system: apps // {
    apps."${system}".default = {
      type = "app";
      program = "${self}/scripts/install";
    };
  })
  ({ })
  configs
