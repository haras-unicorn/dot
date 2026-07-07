{
  machines.nixosModules.programs =
    {
      lib,
      ...
    }:
    {
      options.dot = {
        programs = {
          pinentry = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default pinentry package.
              '';
            };
          };

          chromium = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default chromium package to use.
              '';
            };

            args = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = ''
                Arguments to wrap chromium with.
              '';
            };

            wrap = lib.mkOption {
              type = lib.types.functionTo (lib.types.functionTo lib.types.package);
              description = ''
                Function (package -> string -> package) that takes in a package
                and the name of the binary to wrap with chromium args.
              '';
            };

            launch = lib.mkOption {
              type = lib.types.functionTo (lib.types.functionTo (lib.types.functionTo lib.types.package));
              description = ''
                Function (string -> string -> bool -> package) that takes in a name, an address
                and whether to launch it in incognito mode and makes a package that
                launches chromium at the provided address.
              '';
            };
          };

          mangohud = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default mangohud package.
              '';
            };
          };

          gamemode = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default gamemode package.
              '';
            };
          };
        };
      };
    };

  machines.homeModules.programs =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      options.dot = {
        programs = {
          shell = {
            package = lib.mkOption {
              type = lib.types.package;
              description = "Default shell package";
            };

            sessionVariables = lib.mkOption {
              type =
                with lib.types;
                lazyAttrsOf (oneOf [
                  str
                  path
                  int
                  float
                ]);
              default = { };
              description = ''
                Environment variables to set on session start with Nushell.
              '';
            };

            aliases = lib.mkOption {
              type = with lib.types; lazyAttrsOf str;
              default = { };
              description = ''
                Aliases to use in default shell.
              '';
            };

            sessionStartup = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = ''
                Commands to execute on session start with default shell.
              '';
            };

            copy = lib.mkOption {
              type = lib.types.package;
              description = ''
                Copy command.
              '';
            };

            paste = lib.mkOption {
              type = lib.types.package;
              description = ''
                Paste command.
              '';
            };

            type = lib.mkOption {
              type = lib.types.package;
              description = ''
                Type command.
              '';
            };

            screenshot = lib.mkOption {
              type = lib.types.package;
              description = ''
                Screenshot command.
              '';
            };

            regionshot = lib.mkOption {
              type = lib.types.package;
              description = ''
                Region screenshot command.
              '';
            };

            tree = lib.mkOption {
              type = lib.types.package;
              description = ''
                Directory tree command.
              '';
            };

            list = lib.mkOption {
              type = lib.types.package;
              description = ''
                Directory list command.
              '';
            };
          };

          editor = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default editor package.
              '';
            };
          };

          terminal = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default terminal package.
              '';
            };

            sessionVariables = lib.mkOption {
              type =
                with lib.types;
                lazyAttrsOf (oneOf [
                  str
                  path
                  int
                  float
                ]);
              default = { };
              description = ''
                Environment variables to set on default terminal startup.
              '';
            };
          };

          visual = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default visual editor package.
              '';
            };
          };

          browser = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default browser package.
              '';
            };
          };
        };
      };
    };
}
