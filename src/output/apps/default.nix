{ self
, flake-utils
, ...
}:

flake-utils.eachDefaultSystem (system: {
  apps."${system}".default = {
    type = "app";
    program = "${self}/scripts/install";
  };
})
