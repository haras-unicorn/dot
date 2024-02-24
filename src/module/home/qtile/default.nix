{ pkgs, lib, config, ... }:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# WORKAROUND: these commands on de startup
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service

# TODO: layout command
# TODO: float rules (make it a config thing here)
# TODO: logout button (xfce4-session-logout)?
# TODO: lulezojne
# TODO: resize submap
# TODO: hardware vars
# TODO: location vars
# TODO: fonts
# TODO: callbacks for widgets??

with lib;
let
  cfg = config.de;

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
    ];

    xdg.configFile."qtile/config.py".text = ''
      ${builtins.readFile ./config.py}

      widget_defaults["font"] = "${builtins.toString config.dot.font.sans.name}"
      widget_defaults["fontsize"] = ${builtins.toString config.dot.font.size.medium}
      widget_defaults["icon_size"] = ${builtins.toString config.dot.font.size.medium}

      @hook.subscribe.startup_once
      def startup_once():
          lazy.spawn("systemctl --user import-environment PATH")
          lazy.spawn("systemctl --user restart xdg-desktop-portal.service")

      ${startup}

      ${vars}

      ${binds}
    '';
  };
}
