let
  apiSubmodule = { lib, ... }: {
    options = {
      url = lib.mkOption {
        type = lib.types.str;
        description = "API base url";
      };

      model = lib.mkOption {
        type = lib.types.str;
        description = "Model id";
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

      tpsIn = lib.mkOption {
        type = lib.types.ints.unsigned;
        description = "Token speed in tokens per second for input";
      };

      tpsOut = lib.mkOption {
        type = lib.types.ints.unsigned;
        description = "Token speed in tokens per second for output";
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
      };
    };
  };
}
