{
  machines.nixosModules.nixpkgs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dot = {
        nixpkgs = {
          allowUnfreePredicates = lib.mkOption {
            type = lib.types.listOf (lib.types.functionTo lib.types.bool);
            description = ''
              List of predicates to merge with a logical OR (||)
              for the nixpkgs.config.allowUnfreePredicate option.
            '';
          };
        };
      };

      config = {
        # NOTE: lots of packages broken right now
        nixpkgs.config.rocmSupport = false;
        nixpkgs.config.allowUnfreePredicate =
          package: builtins.any (predicate: predicate package) config.dot.nixpkgs.allowUnfreePredicates;
      };
    };

  machines.homeModules.nixpkgs = { osConfig, ... }: {
    nixpkgs.config = osConfig.nixpkgs.config;
  };
}
