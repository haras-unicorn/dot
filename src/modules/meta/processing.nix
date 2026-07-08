{
  machines.homeModules.processing =
    {
      lib,
      ...
    }:
    let
      common = { name, ... }: {
        options = {
          display = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Display name";
          };
          tags = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Search tags";
          };
          note = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Additional explanatory note";
          };
          package = lib.mkOption {
            type = lib.types.package;
            description = "Package";
          };
          form = lib.mkOption {
            type = lib.types.nullOr lib.types.deferredModule;
            default = null;
            description = "Optional options";
          };
        };
      };
    in
    {
      options.dot = {
        processing = {
          sources = lib.mkOption {
            description = "Processing sources";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ common ];

                options = {
                  output = lib.mkOption {
                    type = lib.types.oneOf [
                      lib.types.str
                      (lib.types.enum [ "detect" ])
                    ];
                    description = "Source output MIME type";
                  };
                };
              }
            );
          };

          nodes = lib.mkOption {
            description = "Processing nodes";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ common ];

                options = {
                  inputs = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      (lib.types.enum [ "any" ])
                    ];
                    description = "Node input MIME types";
                  };
                  output = lib.mkOption {
                    type = lib.types.oneOf [
                      lib.types.str
                      (lib.types.enum [ "detect" ])
                    ];
                    description = "Node output MIME type";
                  };
                };
              }
            );
          };

          sinks = lib.mkOption {
            description = "Processing sinks";
            default = { };
            type = lib.types.attrsOf (
              lib.types.submodule {
                imports = [ common ];

                options = {
                  inputs = lib.mkOption {
                    type = lib.types.oneOf [
                      (lib.types.listOf lib.types.str)
                      (lib.types.enum [ "any" ])
                    ];
                    description = "Sink input MIME types";
                  };
                };
              }
            );
          };
        };
      };
    };
}
