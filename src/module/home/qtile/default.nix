{ pkgs, ... }:


with lib;
let
  cfg = config.de;
in
{
  options.de = {
    sessionVariables = mkOption {
      type = with types; lazyAttrsOf (oneOf [ str path int float ]);
      default = { };
      example = { EDITOR = "hx"; };
      description = ''
        Environment variables to set on session start with Hyprland.
      '';
    };

    sessionStartup = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "keepassxc" ];
      description = ''
        Commands to execute on session start with Hyprland.
      '';
    };

    keybinds = mkOption {
      # TODO: strictly check for the mods, key and command options 
      type = with types; listOf (lazyAttrsOf (oneOf [ str (listOf str) ]));
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
  };

  config = {
    home.packages = with pkgs; [
      qtile
    ];

    xdg.configFile."qtile/config.py".source = ./config.py;
  };
}
