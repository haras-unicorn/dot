let
  common =
    { config, lib, ... }:
    {
      options.dot = {
        services = lib.mkOption {
          description = ''
            Critical services available for service discovery.
          '';
          default = [ ];
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Service name.
                  '';
                };

                address = lib.mkOption {
                  type = lib.types.str;
                  default = config.dot.host.ip;
                  description = ''
                    Service address.
                  '';
                };

                port = lib.mkOption {
                  type = lib.types.port;
                  description = ''
                    Service port.
                  '';
                };

                tls = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = ''
                    Whether to proxy requests without TLS termination.
                  '';
                };

                health = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Service health endpoint in "{tcp/http/https}://{path?}{query?}" format.
                  '';
                };
              };
            }
          );
        };
      };
    };
in
{
  flake.nixosModules.capabilities-services = {
    imports = [ common ];
  };

  flake.homeModules.capabilities-services = {
    imports = [ common ];
  };
}
