let
  common =
    { lib, ... }:
    {
      options.dot = {
        locality = {
          region = lib.mkOption {
            type = lib.types.str;
            default = "origin";
            description = ''
              Host region.
            '';
          };

          dataCenter = lib.mkOption {
            type = lib.types.str;
            default = "biden";
            description = ''
              Host data center.
            '';
          };

          rack = lib.mkOption {
            type = lib.types.str;
            default = "shelf";
            description = ''
              Host rack.
            '';
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-locality = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-locality = {
    imports = [ common ];
  };
}
