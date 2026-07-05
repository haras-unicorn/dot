{
  machines.nixosModules.user =
    {
      lib,
      ...
    }:
    {
      options.dot = {
        user = {
          user = lib.mkOption {
            type = lib.types.str;
            description = "Machine user name.";
          };
          group = lib.mkOption {
            type = lib.types.str;
            description = "Machine user group.";
          };
        };
      };

      config.dot = {
        user = {
          user = "haras";
          group = "haras";
        };
      };
    };
}
