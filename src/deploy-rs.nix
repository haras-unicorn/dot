{
  lib,
  config,
  inputs,
  ...
}:

{
  options.flake.deploy.nodes = lib.mkOption {
    type = lib.types.attrsOf lib.types.raw;
    default = { };
    description = lib.literalMD ''
      Flake deploy nodes to be used with `deploy-rs`.
    '';
  };

  config = {
    flake.nixosModules.deployRs =
      { lib, ... }:
      {
        options = {
          deploy.node = lib.mkOption {
            default = null;
            type = lib.types.nullOr (
              lib.types.submodule {
                options = {
                  hostname = lib.mkOption {
                    type = lib.types.str;
                    description = lib.literalMD ''
                      Deployment host name.
                    '';
                  };

                  sshUser = lib.mkOption {
                    type = lib.types.str;
                    description = lib.literalMD ''
                      Deployment SSH user.
                    '';
                  };
                };
              }
            );
          };
        };
      };

    flake.deploy.nodes =
      builtins.mapAttrs
        (
          _: nixosConfig:
          let
            system = nixosConfig.pkgs.stdenv.hostPlatform.system;
            activateNixos = inputs.deploy-rs.lib.${system}.activate.nixos;
          in
          nixosConfig.config.deploy.node
          // {
            user = "root";
            profiles.system = {
              path = activateNixos nixosConfig;
            };
          }
        )
        (
          lib.filterAttrs (
            _: nixosConfig: nixosConfig ? deploy && nixosConfig.deploy ? node && nixosConfig.deploy.node != null
          ) config.flake.nixosConfigurations
        );

    flake.checks = builtins.mapAttrs (
      system: deployLib: deployLib.deployChecks config.flake.deploy
    ) inputs.deploy-rs.lib;
  };
}
