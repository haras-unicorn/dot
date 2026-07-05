{ config, lib, ... }:

let
  selfLib = config.self.lib;

  flakeLib = lib.filterAttrsRecursive (
    _: value: value ? _selfFlakeLib && value._selfFlakeLib
  ) selfLib;

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
  options.self = {
    lib = lib.mkOption {
      type = recursiveAttrsOf lib.types.raw;
      description = "self library merged attrset";
      default = { };
    };
  };

  config = {
    _module.args.selfLib = selfLib;
    perSystem._module.args.selfLib = selfLib;

    flake.lib = flakeLib;

    self.lib.types.recursiveAttrsOf = recursiveAttrsOf;
  };
}
