{
  machines.homeModules.ai = { lib, ... }: {
    options.dot = {
      ai = {
        models = lib.mkOption {
          default = { };
          description = "Model definitions";
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }: {
                options = {
                  name = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                    description = "Model directory name";
                  };
                  files = lib.mkOption {
                    type = lib.types.listOf lib.types.package;
                    default = [ ];
                    description = "Model directory files";
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
