{ pkgs, lib, ... }:

{
  branch.nixosModule.nixosModule.options.dot.desktopEnvironment = {
    login = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "tuigreet --cmd Hyprland";
      description = ''
        Login command.
      '';
    };

    startup = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options.name = lib.mkOption {
            type = lib.types.str;
            example = "Hyprland";
            description = ''
              Description for the desktop environment.
            '';
          };
          options.command = lib.mkOption {
            type = lib.types.str;
            example = "Hyprland";
            description = ''
              Command to launch the desktop environment;
            '';
          };
        }
      );
    };
  };

  branch.homeManagerModule.homeManagerModule.options.dot.desktopEnvironment = {
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
      example = {
        EDITOR = "hx";
      };
      description = ''
        Environment variables to set on session start with Hyprland.
      '';
    };

    sessionStartup = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "keepassxc" ];
      description = ''
        Commands to execute on session start with Hyprland.
      '';
    };

    fullscreenCheck = lib.mkOption {
      type = lib.types.str;
      default = "false";
      example = ''
        ${pkgs.hyprland}/bin/hyprctl -j activewindow 2>/dev/null \
          | ${pkgs.jq}/bin/jq -e '.fullscreen > 0' >/dev/null
      '';
      description = ''
        Bash if condition that checks whether the active window is fullscreen or not.
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
      example = [
        {
          mods = [ "super" ];
          key = "w";
          command = "firefox";
        }
      ];
      description = ''
        Keybinds to set with Hyprland.
      '';
    };

    windowrules = lib.mkOption {
      type =
        with lib.types;
        listOf (submodule {
          options.rule = lib.mkOption {
            type = lib.types.str;
            example = "float";
            description = "Window rule to apply";
          };
          options.selector = lib.mkOption {
            type = lib.types.str;
            example = "class";
            description = "Selector with which to match";
          };
          options.arg = lib.mkOption {
            type = lib.types.str;
            example = "org.keepassxc.KeePassXC";
            description = "Selector argument with which to match";
          };
        });
      default = [ ];
    };

    volume = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "pwvucontrol";
      description = ''
        Volume command.
      '';
    };

    monitor = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "mission-center";
      description = ''
        Monitor command.
      '';
    };

    network = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "nm-connection-editor";
      description = ''
        Network command.
      '';
    };

    logout = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "wlogout -p layer-shell";
      description = ''
        Logout command.
      '';
    };
  };
}
