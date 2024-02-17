{ self
, flake-utils
}:

flake-utils.eachDefaultSystem (system: {
  apps."${system}".part = {
    type = "app";
    program = "${self}/scripts/part";
  };
})
