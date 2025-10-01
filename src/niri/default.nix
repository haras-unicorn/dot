{
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440

let
  package = pkgs.niri;

  colors = config.lib.stylix.colors.withHashtag;

  cfg = config.dot.desktopEnvironment;

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
        key = lib.strings.toUpper bind.key;
      in
      "${lib.strings.concatStringsSep "+" (mods ++ [ (capitalize key) ])}"
      + " { spawn \"${lib.strings.concatStringsSep "\" \"" (lib.strings.splitString " " bind.command)}\"; }"
    ) cfg.keybinds
  );

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  hasNvidia = config.dot.hardware.graphics.driver == "nvidia";
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasWayland) {
    dot.desktopEnvironment.startup = [
      {
        name = "Niri";
        command = "${package}/bin/niri-session";
      }
    ];

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-niri.json" =
      lib.mkIf hasNvidia
        {
          source = ./50-limit-free-buffer-pool-in-niri.json;
        };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    home.sessionVariables = cfg.sessionVariables;
    systemd.user.sessionVariables = cfg.sessionVariables;

    home.packages = [
      package
      pkgs.xwayland-satellite
    ];

    xdg.configFile."niri/config.kdl".text = ''
      screenshot-path "${config.xdg.userDirs.pictures}/screenshots"

      output "${config.dot.hardware.monitor.main}" {
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
          inactive-color "${colors.green}"
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
