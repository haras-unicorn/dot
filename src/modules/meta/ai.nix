let
  apiSubmodule = { lib, ... }: {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        description = "API base url";
      };

      model = lib.mkOption {
        type = lib.types.str;
        description = "Model id and reference to dot.ai.models";
      };
    };
  };

  multimodalApiSubmodule = { lib, ... }: {
    imports = [ apiSubmodule ];

    options = {
      context = lib.mkOption {
        type = lib.types.ints.unsigned;
        description = "Allocated context size";
      };
      vision = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the API supports vision";
      };
    };
  };

  embeddingApiSubmodule = apiSubmodule;
in
{
  machines.nixosModules.ai = { lib, ... }: {
    options.dot = {
      ai = {
        apis = {
          gpu = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule multimodalApiSubmodule);
            default = null;
            description = "API running inference on the GPU";
          };
          cpu = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule multimodalApiSubmodule);
            default = null;
            description = "API running inference on the CPU";
          };
          embedding = lib.mkOption {
            type = lib.types.nullOr (lib.types.submodule embeddingApiSubmodule);
            default = null;
            description = "Embedding API";
          };
        };

        models = lib.mkOption {
          default = { };
          description = "Model definitions";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, lib, ... }: {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Model name";
                  };
                  family = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Model family";
                  };
                  files = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    description = "Model files (GGUF, config, etc.)";
                  };
                };
              }
            )
          );
        };
      };
    };
  };
}
