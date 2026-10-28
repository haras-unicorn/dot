{ inputs, lib, ... }:

let
  collect =
    depth: prefix: flakeInputs:
    lib.optionalAttrs (depth > 0) (
      lib.concatMapAttrs (
        name: input:
        let
          path = "${prefix}/${name}";
        in
        {
          ${path} = input;
        }
        // lib.optionalAttrs (input ? inputs) (collect (depth - 1) path input.inputs)
      ) flakeInputs
    );
in
{
  perSystem =
    { ... }:
    {
      nix-unit.inputs = collect 3 "haraspkgs" (
        builtins.removeAttrs inputs.haraspkgs.inputs [ "nixpkgs" ]
      );
    };
}
