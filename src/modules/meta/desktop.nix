{
  machines.nixosModules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dot = {
        desktop = {
          login = lib.mkOption {
            type = lib.types.str;
            description = ''
              Login command.
            '';
          };

          startup = lib.mkOption {
            type = lib.types.listOf (
              lib.types.submodule {
                options.name = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Desktop environement label (Wayland) or identifier (XServer).
                  '';
                };
                options.type = lib.mkOption {
                  type = lib.types.enum [
                    "wayland"
                    "xserver"
                  ];
                  default = "wayland";
                  description = ''
                    Session type.
                  '';
                };
                options.command = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Command to launch the desktop environment;
                  '';
                };
              }
            );
          };

          sessions = lib.mkOption {
            type = lib.types.package;
            description = ''
              Session startup files directory.
            '';
          };
        };
      };
    };

  machines.homeModules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      options.dot = {
        desktop = {
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
              Environment variables to set on session start with Hyprland.
            '';
          };

          sessionStartup = lib.mkOption {
            type = with lib.types; listOf str;
            default = [ ];
            description = ''
              Commands to execute on session start with Hyprland.
            '';
          };

          fullscreenChecks = lib.mkOption {
            type = lib.types.attrsOf lib.types.package;
            default = { };
            description = ''
              Packages that exit 0 if active window is fullscreen
              and 1 if active window is not fullscreen.
            '';
          };

          keybinds = lib.mkOption {
            # TODO: strictly check for the mods, key and command options
            type =
              with lib.types;
              listOf (
                lazyAttrsOf (oneOf [
                  str
                  (listOf str)
                ])
              );
            default = [ ];
            description = ''
              Keybinds to set with the selected desktop environment.
            '';
          };

          windowrules = lib.mkOption {
            type =
              with lib.types;
              listOf (submodule {
                options.rule = lib.mkOption {
                  type = lib.types.str;
                  description = "Window rule to apply";
                };
                options.selector = lib.mkOption {
                  type = lib.types.str;
                  description = "Selector with which to match";
                };
                options.arg = lib.mkOption {
                  type = lib.types.str;
                  description = "Selector argument with which to match";
                };
              });
            default = [ ];
          };

          volume = lib.mkOption {
            type = lib.types.str;
            description = ''
              Volume command.
            '';
          };

          monitor = lib.mkOption {
            type = lib.types.str;
            description = ''
              Monitor command.
            '';
          };

          network = lib.mkOption {
            type = lib.types.str;
            description = ''
              Network command.
            '';
          };

          logout = lib.mkOption {
            type = lib.types.str;
            description = ''
              Logout command.
            '';
          };

          screenshots = lib.mkOption {
            type = lib.types.path;
            default = "${config.xdg.userDirs.pictures}/screenshots";
            description = ''
              Screenshot location.
            '';
          };

          capture = lib.mkOption {
            type = lib.types.path;
            default = "${config.xdg.userDirs.videos}/capture";
            description = ''
              Video capture location.
            '';
          };

          recording = lib.mkOption {
            type = lib.types.path;
            default = "${config.xdg.userDirs.music}/recording";
            description = ''
              Audio recording location.
            '';
          };

          timestamp = lib.mkOption {
            type = lib.types.str;
            default = "+%Y-%m-%d_%H-%M-%S";
            description = ''
              Screenshot/capture/recording timestamp format.
            '';
          };
        };
      };
    };
}
