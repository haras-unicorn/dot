{ pkgs, lib, config, ... }:

# TODO: add dot prefix
# TODO: map bind mods
# TODO: switch-layout command
# TODO: lulezojne
# TODO: logout button (xfce4-session-logout)?
# TODO: resize submap
# TODO: float rules (make it a config thing here)
# TODO: hardware vars
# TODO: location vars
# TODO: fonts
# TODO: callbacks for widgets??

with lib;
let
  cfg = config.de;

  reload-de = pkgs.writeShellApplication {
    name = "reload-de";
    runtimeInputs = [ pkgs.qtile ];
    text = ''
      qtile cmd-obj -o cmd -f restart
    '';
  };

  startup = strings.concatStringsSep
    "\n"
    (builtins.map
      (command: ''
        @hook.subscribe.startup_once
        def startup_once():
            lazy.spawn("${builtins.toString command}")

      '')
      cfg.sessionStartup);

  vars = strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''
        os.environ["${name}"] = "${builtins.toString cfg.sessionVariables."${name}"}"
      '')
      (builtins.attrNames cfg.sessionVariables));

  binds = strings.concatStringsSep
    "\n"
    (builtins.map
      (bind:
        let
          mods = builtins.map
            (mod:
              if mod == "super" then
                "mod4"
              else
                if mod == "alt" then
                  "mod1"
                else
                  mod)
            bind.mods;

          modString =
            if (builtins.length mods) == 0 then
              ""
            else
              ''"${strings.concatStringsSep ''", "'' mods}"'';
        in
        ''
          keys.append(
              Key(
                  [${modString}],
                  "${bind.key}",
                  lazy.spawn("${bind.command}")
              )
          )
        '')
      cfg.keybinds);
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
      reload-de
    ];

    xdg.configFile."qtile/config.py".text = ''
      ${builtins.readFile ./config.py}

      ${startup}

      ${vars}

      ${binds}
    '';
  };
}
