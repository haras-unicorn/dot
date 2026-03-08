let
  common =
    { lib, ... }:
    {
      options.dot = {
        openai = {
          apis = lib.mkOption {
            description = "OpenAI APIs";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  secret = lib.mkOption {
                    type = lib.types.str;
                    description = "SOPS secret";
                  };
                  systemKey = lib.mkOption {
                    type = lib.types.str;
                    description = "System key path";
                  };
                  homeKey = lib.mkOption {
                    type = lib.types.str;
                    description = "User-accessible key path";
                  };
                };
              }
            );
          };
        };
      };
    };
in
{
  flake.nixosModules.capabilities-openai = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-openai = {
    imports = [ common ];
  };
}
