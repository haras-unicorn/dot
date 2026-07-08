# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440

{
  machines.nixosModules.niri =
    {
      pkgs,
      lib,
      config,
      flake,
      ...
    }:
    let
      package = pkgs.niri;

      hardware = config.dot.hardware;
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.desktop.startup = lib.mkBefore [
        {
          name = "Niri";
          type = "wayland";
          command = lib.getExe' package "niri-session";
        }
      ];
    };

  machines.homeModules.niri =
    {
      pkgs,
      lib,
      config,
      osConfig,
      ...
    }:
    let
      hardware = osConfig.dot.hardware;

      package = pkgs.niri;

      colors = config.lib.stylix.colors.withHashtag;

      cfg = config.dot.desktop;

      capitalize =
        x:
        builtins.foldl' (char: string: char + string) "" (
          pkgs.lib.lists.imap0 (i: x: if i == 0 then (pkgs.lib.strings.toUpper x) else x) (
            pkgs.lib.strings.stringToCharacters x
          )
        );

      vars = lib.strings.concatStringsSep "\n  " (
        builtins.map (name: "${name} \"${builtins.toString cfg.sessionVariables."${name}"}\"") (
          builtins.attrNames cfg.sessionVariables
        )
      );

      startup = lib.strings.concatStringsSep "\n" (
        builtins.map (
          command:
          "spawn-at-startup \"${lib.strings.concatStringsSep "\" \"" (lib.strings.splitString " " command)}\""
        ) cfg.sessionStartup
      );

      binds = lib.strings.concatStringsSep "\n  " (
        builtins.map (
          bind:
          let
            mods = builtins.map (
              mod:
              if mod == "super" then
                "Mod"
              else if mod == "alt" then
                "Alt"
              else if mod == "ctrl" then
                "Ctrl"
              else if mod == "shift" then
                "Shift"
              else
                mod
            ) bind.mods;
          in
          "${lib.strings.concatStringsSep "+" (mods ++ [ (capitalize bind.key) ])}"
          + " { spawn \"${lib.strings.concatStringsSep "\" \"" (lib.strings.splitString " " bind.command)}\"; }"
        ) cfg.keybinds
      );

      windowrules = lib.strings.concatStringsSep "\n" (
        builtins.map (
          windowrule:
          let
            rule =
              if windowrule.rule == "float" then
                "open-floating true"
              else if windowrule.rule == "hide" then
                ''
                  open-floating true
                  default-column-width { fixed 0; }
                  default-window-height { fixed 0; }
                  max-width 0
                  max-height 0
                  default-floating-position x=0 y=0 relative-to="bottom-left"
                ''
              else
                builtins.throw "Unknown window rule";

            selector =
              if windowrule.selector == "class" then "app-id" else builtins.throw "Unknown window selector";
          in
          ''
            window-rule {
              match ${selector}="${windowrule.arg}"
              ${rule}
            }
          ''
        ) cfg.windowrules
      );

      fullscreenCheck = pkgs.writeShellApplication {
        name = "niri-fullscreen-check";
        runtimeInputs = [
          pkgs.niri
          pkgs.jq
        ];
        text = ''
          window_info=$(niri msg --json focused-window 2>/dev/null)
          window_width=$(echo "$window_info" | jq -r '.layout.window_size[0]')
          window_height=$(echo "$window_info" | jq -r '.layout.window_size[1]')

          # check if window size matches monitor (with small margin for rounding)
          if [ "$window_width" -ge ${toString (hardware.width - 5)} ] && \
             [ "$window_height" -ge ${toString (hardware.height - 5)} ]; then
            exit 0  # is fullscreen
          else
            exit 1  # not fullscreen
          fi
        '';
      };
    in
    lib.mkIf (hardware.visual && hardware.wayland) {
      dot.desktop.fullscreenChecks = {
        niri = fullscreenCheck;
      };

      home.sessionVariables = cfg.sessionVariables;
      systemd.user.sessionVariables = cfg.sessionVariables;

      home.packages = [
        package
        pkgs.xwayland-satellite
      ];

      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-gnome
      ];
      xdg.portal.config.niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Access" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
      };

      xdg.configFile."niri/config.kdl".text = ''
        screenshot-path "${config.dot.desktop.screenshots}"

        output "${hardware.display}" {
          variable-refresh-rate
        }

        cursor {
          xcursor-theme "${config.stylix.cursor.name}"
          xcursor-size ${builtins.toString config.stylix.cursor.size}
        }

        ${builtins.readFile ./config.kdl}

        environment {
          ${vars}
        }

        ${startup}

        binds {
          ${builtins.readFile ./binds.kdl}
          ${binds}
        }

        ${windowrules}

        layout {
          focus-ring {
            width 0
          }
          border {
            width 2
            active-gradient \
            	from="${colors.yellow}" \
            	to="${colors.magenta}" \
            	angle=45 \
            	relative-to="workspace-view"
            inactive-color "${colors.cyan}"
          }
          gaps 4
          struts {
            top 8
            bottom 8
            left 8
            right 8
          }
        }
      '';
    };
}
