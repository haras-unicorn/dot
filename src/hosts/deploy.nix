{
  deploy-rs,
  lib,
  config,
  ...
}:

let
  deployNodeSubmodule = {
    options.hostname = lib.mkOption {
      type = lib.types.str;
      description = lib.literalMD ''
        Deployment host name.
      '';
    };
    options.sshUser = lib.mkOption {
      type = lib.types.str;
      description = lib.literalMD ''
        Deployment SSH user.
      '';
    };
  };
in
{
  options.seal.deploy.nodes = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule deployNodeSubmodule);
    default = { };
    description = lib.literalMD ''
      Extra data needed to create `deploy.nodes` flake output.
    '';
  };

  options.seal.defaults.nixosConfigurationsAsDeployNodes = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = lib.literalMD ''
      Convert all packages to apps.
    '';
  };

  options.propagate.deploy = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
    default = { };
    description = lib.literalMD ''
      Propagated `deploy.nodes` flake output.
    '';
  };

  config.propagate.deploy.nodes =
    if !config.seal.defaults.nixosConfigurationsAsDeployNodes then
      { }
    else
      let
        systems = builtins.attrNames deploy-rs.lib;

        systemsFor =
          configuration:
          builtins.filter ({ value, ... }: value != null) (
            builtins.map (
              system:
              let
                name = "${configuration}-${system}";
              in
              {
                inherit configuration system name;
                value =
                  if config.flake.nixosConfigurations ? ${name} then
                    config.flake.nixosConfigurations.${name}
                  else
                    null;
              }
            ) systems
          );
      in
      builtins.listToAttrs (
        lib.flatten (
          builtins.map
            (
              { configuration, submodule }:
              builtins.map (
                {
                  name,
                  system,
                  value,
                  ...
                }:
                {
                  inherit name;
                  value = submodule // {
                    user = "root";
                    profiles.system = {
                      path = deploy-rs.lib.${system}.activate.nixos value;
                    };
                  };
                }
              ) (systemsFor configuration)
            )
            (
              lib.mapAttrsToList (name: value: {
                configuration = name;
                submodule = value;
              }) config.seal.deploy.nodes
            )
        )
      );

  config.flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks config.flake.deploy
  ) deploy-rs.lib;
}
