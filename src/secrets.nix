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

  sopsOption = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = lib.literalMD ''
      Which files to include in the sops file.
    '';
  };

  specificationSubmodule.options = {
    imports = importsOption;
    generations = generationsOption;
    exports = exportsOption;
  };
in
{
  options.seal.rumor.specifications = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.submodule specificationSubmodule);
    default = { };
    description = lib.literalMD ''
      Rumor specifications.
    '';
  };

  options.seal.rumor.sopsDir = lib.mkOption {
    type = lib.types.str;
    description = lib.literalMD ''
      Where to put the sops file.
    '';
  };

  options.propagate.rumor = lib.mkOption {
    type =
      lib.types.attrsOf
        (lib.types.submodule specificationSubmodule);
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

  config.branch.nixosModule.nixosModule = {
    options.rumor.specification = {
      imports = importsOption;
      generations = generationsOption;
      exports = exportsOption;
    };
    options.rumor.sops = sopsOption;
  };

  config.propagate.rumor =
    if !config.seal.defaults.nixosConfigurationsAsRumor
    then { }
    else
      let
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
              perch.lib.defaults.systems);
      in
      builtins.listToAttrs
        (lib.flatten
          (builtins.map
            ({ configuration, submodule }:
              builtins.map
                ({ name, system, value, ... }: {
                  inherit name;
                  value = {
                    imports = submodule.imports
                      ++ value.config.rumor.specification.imports;
                    generations = submodule.generations
                      ++ value.config.rumor.specification.generations
                      ++ [
                      {
                        generator = "age";
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
                          secrets =
                            builtins.listToAttrs
                              (builtins.map
                                (file: {
                                  name = file;
                                  value = file;
                                })
                                value.config.rumor.sops);
                        };
                      }
                    ];
                    exports = submodule.exports
                      ++ value.config.rumor.specification.exports
                      ++ [{
                      exporter = "copy";
                      arguments = {
                        from = "sops-public";
                        to = "../${config.seal.rumor.sopsDir}/${configuration}.yaml";
                      };
                    }];
                  };
                })
                (systemsFor configuration))
            (lib.mapAttrsToList
              (name: value: {
                configuration = name;
                submodule = value;
              })
              config.seal.rumor.specifications)));

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
