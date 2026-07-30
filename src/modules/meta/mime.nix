{
  machines.homeModules.mime =
    { lib, ... }:
    {
      options.dot = {
        mime = {
          apps = lib.mkOption {
            description = "List of applications to associate with mime types.";
            default = [ ];
            type = lib.types.listOf (
              lib.types.submodule {
                options = {
                  package = lib.mkOption {
                    type = lib.types.package;
                    description = "Application package.";
                  };
                  types = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    description = "List of mime types to associate.";
                  };
                };
              }
            );
          };
        };
      };
    };
}
