{ lib, config, perch, ... }:

let
  importsOption = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
    description = lib.literalMD ''
      Rumor `imports` specification value.
    '';
  };

  generationsOption = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
    description = lib.literalMD ''
      Rumor `generations` specification value.
    '';
  };

  exportsOption = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [ ];
    description = lib.literalMD ''
      Rumor `exports` specification value.
    '';
  };

  submodule.options = {
    imports = importsOption;
    generations = generationsOption;
    exports = exportsOption;
  };
in
{
  options.seal.rumor = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.submodule submodule);
    default = { };
    description = lib.literalMD ''
      Rumor specifications.
    '';
  };

  options.propagate.rumor = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.submodule submodule);
    default = { };
    description = lib.literalMD ''
      Rumor specifications.
    '';
  };

  options.seal.defaults.nixosConfigurationsAsRumor = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = lib.literalMD ''
      Convert all nixos configurations to rumor.
    '';
  };

  config.integrate.nixosModule.nixosModule = {
    options.rumor = {
      imports = importsOption;
      generations = generationsOption;
      exports = exportsOption;
    };
  };

  config.propagate.rumor =
    if !config.seal.defaults.nixosConfigurationsAsRumor
    then { }
    else
      let
        systems = builtins.attrNames perch.lib.defaults.systems;

        systemsFor = configuration:
          builtins.filter
            ({ value, ... }: value != null)
            (builtins.map
              (system:
                let
                  name = "${configuration}-${system}";
                in
                {
                  inherit configuration system name;
                  value =
                    if config.flake.nixosConfigurations ? ${name}
                    then config.flake.nixosConfigurations.${name}
                    else null;
                })
              systems);
      in
      builtins.listToAttrs
        (lib.flatten
          (builtins.map
            ({ configuration, submodule }:
              builtins.map
                ({ name, system, value, ... }: {
                  inherit name;
                  value = submodule // {
                    imports = submodule.imports
                      ++ value.config.rumor.imports;
                    generations = submodule.generations
                      ++ value.config.rumor.generations;
                    exports = submodule.exports
                      ++ value.config.rumor.exports;
                  };
                })
                (systemsFor configuration))
            (lib.mapAttrsToList
              (name: value: {
                configuration = name;
                submodule = value;
              })
              config.seal.rumor)));

  # TODO: pkgs.runCommand with rumor validate
  config.flake.checks =
    builtins.listToAttrs
      (builtins.map
        (system:
          {
            name = system;
            value = { };
          })
        perch.lib.defaults.systems);
}
