{ config, lib, ... }:

let
  recursiveAttrsOf =
    elemType:
    lib.types.mkOptionType {
      name = "recursiveAttrsOf";
      description = "nested attribute set of ${elemType.description or "values"}";
      descriptionClass = "noun";
      check = value: lib.isAttrs value;
      merge = loc: defs: lib.foldl' lib.recursiveUpdate { } (builtins.map (def: def.value) defs);
    };
in
{
  options.libAttrs = lib.mkOption {
    type = recursiveAttrsOf lib.types.raw;
    description = "Flake library that is merged across flake modules";
    default = { };
  };

  config = {
    flake.lib = config.libAttrs;

    libAttrs.types.recursiveAttrsOf = recursiveAttrsOf;
  };
}
