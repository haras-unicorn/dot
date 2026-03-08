let
  common =
    { lib, ... }:
    {
      options.dot = {
        chromium = {
          package = lib.mkOption {
            type = lib.types.package;
            description = ''
              Default chromium package to use.
            '';
          };

          args = lib.mkOption {
            type = lib.types.raw;
            description = ''
              Arguments to wrap chromium with.
            '';
          };

          wrap = lib.mkOption {
            type = lib.types.raw;
            description = ''
              Function (package -> string -> package) that takes in a package
              and the name of the binary to wrap with chromium args.
            '';
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-chromium = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-chromium = {
    imports = [ common ];
  };
}
