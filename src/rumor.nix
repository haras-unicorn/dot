{
  inputs,
  lib,
  config,
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
          Rumor `imports` specification value.
        '';
      };

      generations = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = lib.literalMD ''
          Rumor `generations` specification value.
        '';
      };

      exports = lib.mkOption {
        type = lib.types.listOf lib.types.raw;
        default = [ ];
        description = lib.literalMD ''
          Rumor `exports` specification value.
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
    options.rumor.sopsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = lib.literalMD ''
        Where to put the sops file.
      '';
    };

    options.flake.rumor = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            specification = mkSpecificationSubmodule { inherit lib; };
          };
        }
      );
      default = { };
      description = lib.literalMD ''
        Rumor specifications.
      '';
    };
  };

  config = {
    flake.nixosModules.rumor =
      { lib, ... }:
      {
        options.rumor = lib.mkOption {
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

    flake.rumor =
      builtins.mapAttrs
        (name: nixosConfig: {
          imports = nixosConfig.config.rumor.specification.imports;
          generations =
            nixosConfig.config.rumor.specification.generations
            ++ (lib.optionals ((builtins.length nixosConfig.config.rumor.sops.keys) != 0) [
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
                    }) nixosConfig.config.rumor.sops.keys
                  );
                };
              }
            ]);
          exports =
            nixosConfig.config.rumor.specification.exports
            ++ (lib.optionals
              (
                (builtins.length nixosConfig.config.rumor.sops.keys) != 0
                && nixosConfig.config.rumor.sops.path != null
              )
              [
                {
                  exporter = "copy";
                  arguments = {
                    from = "sops-public";
                    to = nixosConfig.config.rumor.sops.path;
                  };
                }
              ]
            );
        })
        (
          lib.filterAttrs (
            _: conf: conf.config ? rumor && conf.config.rumor != null
          ) config.flake.nixosConfigurations
        );

    flake.checks = builtins.mapAttrs (
      system:
      { rumor, ... }:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
        };
      in
      {
        rumor-schema =
          pkgs.runCommand "rumor-schema"
            {
              nativeBuildInputs = [
                rumor
              ];
            }
            ''
              # TODO: run validation when subcommand exists in rumor
              touch "$out"
            '';
      }
    ) (lib.filterAttrs (_: systemPackages: systemPackages ? rumor) inputs.rumor.packages);
  };
}
