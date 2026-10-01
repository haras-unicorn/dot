{ inputs, ... }:

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
          allowUnfreePackageNames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = ''
              List of package names to convert to a predicate
              in dot.nixpkgs.allowUnfreePredicates.
            '';
          };

          allowUnfreePredicates = lib.mkOption {
            type = lib.types.listOf (lib.types.functionTo lib.types.bool);
            default = [ ];
            description = ''
              List of predicates to merge with a logical OR (||)
              for the nixpkgs.config.allowUnfreePredicate option.
            '';
          };
        };
      };

      config =
        let
          hardware = config.dot.hardware;
        in
        {
          _module.args.unstablePkgs = import inputs.nixpkgs-unstable {
            system = pkgs.stdenv.hostPlatform.system;
          };

          dot.nixpkgs.allowUnfreePredicates = [
            (
              package:
              builtins.any (name: (lib.getName package == name)) config.dot.nixpkgs.allowUnfreePackageNames
            )
          ];

          nixpkgs.config.cudaSupport = hardware.cuda;
          # NOTE: lots of packages broken right now
          nixpkgs.config.rocmSupport = hardware.rocm;
          nixpkgs.config.allowUnfreePredicate =
            package: builtins.any (predicate: predicate package) config.dot.nixpkgs.allowUnfreePredicates;
        };
    };

  machines.homeModules.nixpkgs = { osConfig, ... }: {
    _module.args.unstablePkgs = osConfig._module.args.unstablePkgs;
    nixpkgs.config = osConfig.nixpkgs.config;
  };
}
