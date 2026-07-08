{
  machines.nixosModules.profile =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dot = {
        profile = {
          image = lib.mkOption {
            type = lib.types.str;
            description = ''
              Path to the profile image.
            '';
          };
        };
      };
    };
}
