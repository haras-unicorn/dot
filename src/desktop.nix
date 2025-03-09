{ lib, ... }:

{
  integrate.nixosModule.nixosModule.options.dot.desktopEnvironment = {
    login = lib.mkOption {
      type = lib.types.str;
      default = [ ];
      example = "tuigreet --cmd Hyprland";
      description = ''
        Login command.
      '';
    };

    startup = lib.mkOption {
      type = lib.types.str;
      example = "Hyprland";
      description = ''
        Command to launch desktop environment.
      '';
    };
  };

  integrate.homeManagerModule.homeManagerModule.options.dot.desktopEnvironment = {
    sessionVariables = lib.mkOption {
      type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
      default = { };
      example = { EDITOR = "hx"; };
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

    keybinds = lib.mkOption {
      # TODO: strictly check for the mods, key and command options 
      type = with lib.types; listOf (lazyAttrsOf (oneOf [ str (listOf str) ]));
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
      type = with lib.types; listOf (lazyAttrsOf (str));
      default = [ ];
      example = [
        {
          rule = "float";
          selector = "class";
          xselector = "wm_class";
          arg = "org.keepassxc.KeePassXC";
          xarg = "keepassxc";
        }
      ];
    };
  };
}
