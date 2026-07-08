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
          image = lib.mkOption {
            type = lib.types.path;
            description = "Path to the profile image.";
          };
        };
      };
    };
}
