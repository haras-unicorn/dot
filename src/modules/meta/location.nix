{
  machines.nixosModules.location =
    { lib, ... }:
    {
      options.dot = {
        location = {
          latitude = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.int
              lib.types.float
            ];
            description = ''
              Location latitude.
            '';
          };

          longitude = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.int
              lib.types.float
            ];
            description = ''
              Location longitude.
            '';
          };

          altitude = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.int
              lib.types.float
            ];
            default = 0;
            description = ''
              Location altitude in meters.
            '';
          };

          accuracy = lib.mkOption {
            type = lib.types.oneOf [
              lib.types.int
              lib.types.float
            ];
            description = ''
              Location accuracy in meters.
            '';
          };

          address = lib.mkOption {
            type = lib.types.str;
            description = ''
              Free-form location address (e.g. city name).
            '';
          };
        };
      };
    };
}
