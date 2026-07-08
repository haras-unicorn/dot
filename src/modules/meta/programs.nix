{
  machines.nixosModules.programs =
    {
      lib,
      ...
    }:
    {
      options.dot = {
        programs = {
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
              type = lib.types.functionTo lib.types.package;
              description = ''
                Function (package -> package) that takes in a package
                or path to wrap with chromium args.
              '';
            };

            launch = lib.mkOption {
              type = lib.types.functionTo lib.types.package;
              description = ''
                Function (attrs -> package) that takes in attrs and makes
                a program that launches chromium at the provided address.

                Attrs:
                - name: Final package name.
                - address: Address to navigate to.
                - incognito: Whether to launch chromium in incognito.
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

            sessionStartup = lib.mkOption {
              type = with lib.types; listOf str;
              default = [ ];
              description = ''
                Commands to execute on session start with default shell.
              '';
            };

            aliases = lib.mkOption {
              type = with lib.types; lazyAttrsOf str;
              default = { };
              description = ''
                Aliases to use in default shell.
              '';
            };
          };

          pager = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default pager package.
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

          files = {
            package = lib.mkOption {
              type = lib.types.package;
              description = ''
                Default file manager package.
              '';
            };
          };
        };
      };
    };
}
