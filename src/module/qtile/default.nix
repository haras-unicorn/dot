{ lib, config, ... }:

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

let
  cfg = config.dot.desktopEnvironment;

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: ''
        @hook.subscribe.startup_once
        def startup_once():
            lazy.spawn("${builtins.toString command}")

      '')
      cfg.sessionStartup);

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: ''
        os.environ["${name}"] = "${builtins.toString cfg.sessionVariables."${name}"}"
      '')
      (builtins.attrNames cfg.sessionVariables));

  binds = lib.strings.concatStringsSep
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
              ''"${lib.strings.concatStringsSep ''", "'' mods}"'';
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

  # TODO: use windowrules
  # windowrules = lib.strings.concatStringsSep
  #   "\n"
  #   (builtins.map
  #     (windowrule: "windowrulev2 ="
  #       + " ${windowrule.rule}"
  #       + ", ${windowrule.selector}:(${windowrule.arg})")
  #     cfg.windowrules);
in
{
  options.dot.desktopEnvironment = {
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
          arg = "org.keepassxc.KeePassXC";
        }
      ];
    };
  };

  config = {
    shared.dot = {
      desktopEnvironment.session = "qtile";
    };

    system = {
      services.xserver.windowManager.qtile.enable = true;
      services.xserver.windowManager.qtile.extraPackages =
        python3Packages: with python3Packages; [
          psutil
        ];
    };

    home.shared = {
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
  };
}
