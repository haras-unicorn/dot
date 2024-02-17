{ self
, flake-utils
, ...
}:

flake-utils.lib.eachDefaultSystem (system: {
  apps."${system}".default = {
    type = "app";
    program = "${self}/scripts/install";
  };
})
