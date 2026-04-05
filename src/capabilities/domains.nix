{ config, ... }:

let
  common =
    { lib, ... }:
    {
      options.dot = {
        domains = {
          topLevel = lib.mkOption {
            type = lib.types.str;
            description = ''
              Top-level domain.
            '';
          };

          service = lib.mkOption {
            type = lib.types.str;
            description = ''
              Service domain.
            '';
          };

          node = lib.mkOption {
            type = lib.types.str;
            description = ''
              Node domain.
            '';
          };
        };
      };
    };
in
{
  imports = [ common ];

  flake.nixosModules.capabilities-domains = {
    imports = [ common ];

    config.dot.domains = config.dot.domains;
  };

  flake.homeModules.capabilities-domains = {
    imports = [ common ];

    config.dot.domains = config.dot.domains;
  };
}
