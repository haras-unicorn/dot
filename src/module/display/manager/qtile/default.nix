{ pkgs, lib, config, ... }:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# WORKAROUND: these commands on de startup
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service

let
  cfg = config.dot.desktopEnvironment;

  bootstrap = config.dot.colors.bootstrap;

  package = pkgs.qtile-unwrapped;

  current-layout = pkgs.writeShellApplication {
    name = "current-layout";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .active_keymap' | \
      #   head -n 1
    '';
  };

  switch-layout = pkgs.writeShellApplication {
    name = "switch-layout";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .name' | \
      #   xargs -IR sh -c 'hyprctl switchxkblayout R next &>/dev/null'

      ${current-layout}/bin/current-layout
    '';
  };

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

  windowrules = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (windowrule: "floating_layout.float_rules.append(Match(${windowrule.xselector}=\"${windowrule.xarg}\"))")
      (builtins.filter
        (windowrule: windowrule.rule == "float")
        cfg.windowrules));

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  options.desktopEnvironment = {
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
    shared = lib.mkIf (hasMonitor && !hasWayland) {
      dot = {
        desktopEnvironment.session = "qtile";
      };
    };

    system = lib.mkIf (hasMonitor && !hasWayland) {
      services.xserver.windowManager.qtile.enable = true;
      services.xserver.windowManager.qtile.package = package;
      services.xserver.windowManager.qtile.extraPackages =
        python3Packages: with python3Packages; [
          psutil
        ];
    };

    home = lib.mkIf (hasMonitor && !hasWayland) {
      home.packages = [
        switch-layout
        current-layout
      ];

      home.activation = {
        qtileReloadAction = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${package}/bin/qtile cmd-obj -f reload_config || true
        '';
      };

      xdg.configFile."qtile/config.py".text = ''
        colors = {
          "background": "${bootstrap.background.normal.hex}",
          "text": "${bootstrap.text.normal.hex}",
          "danger": "${bootstrap.danger.normal.hex}",
          "danger-alternate": "${bootstrap.danger.alternate.hex}",
          "primary": "${bootstrap.primary.normal.hex}",
          "accent": "${bootstrap.accent.normal.hex}"
        }

        ${builtins.readFile ./config.py}

        widget_defaults["font"] = "${builtins.toString config.dot.font.sans.name}"
        widget_defaults["fontsize"] = ${builtins.toString config.dot.font.size.medium}
        widget_defaults["icon_size"] = ${builtins.toString config.dot.font.size.medium}

        keys.append(
            Key(
                ["mod4"],
                "space",
                lazy.spawn("${switch-layout}/bin/switch-layout")
            )
        )

        @hook.subscribe.startup_once
        def startup_once():
            lazy.spawn("systemctl --user import-environment PATH")
            lazy.spawn("systemctl --user restart xdg-desktop-portal.service")

        ${startup}

        ${vars}

        ${binds}

        ${windowrules}
      '';
    };
  };
}
