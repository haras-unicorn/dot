{
  inputs,
  lib,
  self,
  ...
}:

let
  mkSpecificationSubmodule =
    { lib }:
    {
      imports = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = lib.literalMD ''
          Cryl `imports` specification value.
        '';
      };

      generations = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = lib.literalMD ''
          Cryl `generations` specification value.
        '';
      };

      exports = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = lib.literalMD ''
          Cryl `exports` specification value.
        '';
      };
    };

  mkSopsSubmodule =
    { lib }:
    {
      keys = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = lib.literalMD ''
          Which files to include in the sops file.
        '';
      };

      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = lib.literalMD ''
          Where to put the sops file.
        '';
      };
    };
in
{
  options = {
    flake.cryl = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            specification = mkSpecificationSubmodule { inherit lib; };
          };
        }
      );
      default = { };
      description = lib.literalMD ''
        Cryl specifications.
      '';
    };
  };

  config = {
    libAttrs.cryl.shared = "kv/dot/shared";

    flake.nixosModules.cryl =
      { lib, ... }:
      {
        options.cryl = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.submodule {
              options = {
                specification = mkSpecificationSubmodule { inherit lib; };
                sops = mkSopsSubmodule { inherit lib; };
              };
            }
          );
          default = null;
        };
      };

    flake.cryl =
      builtins.mapAttrs
        (name: nixosConfig: {
          imports = nixosConfig.config.cryl.specification.imports;
          generations =
            nixosConfig.config.cryl.specification.generations
            ++ (lib.optionals ((builtins.length nixosConfig.config.cryl.sops.keys) != 0) [
              {
                generator = "age-key";
                arguments = {
                  private = "age-private";
                  public = "age-public";
                };
              }
              {
                generator = "sops";
                arguments = {
                  renew = true;
                  age = "age-public";
                  private = "sops-private";
                  public = "sops-public";
                  secrets = builtins.listToAttrs (
                    builtins.map (file: {
                      name = file;
                      value = file;
                    }) nixosConfig.config.cryl.sops.keys
                  );
                };
              }
            ]);
          exports =
            nixosConfig.config.cryl.specification.exports
            ++ (lib.optionals
              (
                (builtins.length nixosConfig.config.cryl.sops.keys) != 0
                && nixosConfig.config.cryl.sops.path != null
              )
              [
                {
                  exporter = "copy";
                  arguments = {
                    from = "sops-public";
                    to = nixosConfig.config.cryl.sops.path;
                  };
                }
              ]
            );
        })
        (
          lib.filterAttrs (_: conf: conf.config ? cryl && conf.config.cryl != null) self.nixosConfigurations
        );

    flake.checks = builtins.mapAttrs (
      system:
      { cryl, ... }:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
      in
      {
        cryl-schema =
          pkgs.runCommand "cryl-schema"
            {
              nativeBuildInputs = [
                cryl
              ];
            }
            ''
              # TODO: run validation when subcommand exists in cryl
              touch "$out"
            '';
      }
    ) (lib.filterAttrs (_: systemPackages: systemPackages ? cryl) inputs.cryl.packages);
  };
}
