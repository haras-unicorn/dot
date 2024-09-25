{ pkgs, lib, config, ... }:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# FIXME: colors import
# FIXME: xwayland
# WORKAROUND: these commands on de startup
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service
# TODO: remove niri- prefixes and add in the commented out options

let
  cfg = config.dot.desktopEnvironment;

  current-layout = pkgs.writeShellApplication {
    name = "niri-current-layout";
    runtimeInputs = [ pkgs.niri pkgs.jq ];
    text = ''
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .active_keymap' | \
      #   head -n 1
    '';
  };

  switch-layout = pkgs.writeShellApplication {
    name = "niri-switch-layout";
    runtimeInputs = [ pkgs.niri pkgs.jq ];
    text = ''
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .name' | \
      #   xargs -IR sh -c 'hyprctl switchxkblayout R next &>/dev/null'

      # ${current-layout}/bin/current-layout
    '';
  };

  capitalize = builtins.foldl'
    (char: string: char + string)
    ""
    (pkgs.lib.lists.imap0
      (i: x: if i == 0 then (pkgs.lib.strings.toUpper x) else x)
      (pkgs.lib.strings.stringToCharacters "enter"));

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: "${name} \"${builtins.toString cfg.sessionVariables."${name}"}\"")
      (builtins.attrNames cfg.sessionVariables));

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "spawn-at-startup \"${builtins.toString command}\"")
      cfg.sessionStartup);

  binds = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (bind:
        let
          mods = builtins.map
            (mod:
              if mod == "super" then "Mod"
              else if mod == "alt" then "Alt"
              else if mod == "ctrl" then "Ctrl"
              else if mod == "shift" then "Shift"
              else mod)
            bind.mods;
          key = lib.strings.toUpper bind.key;
        in
        "${lib.strings.concatStringsSep "+" (mods ++ [capitalize key])}"
        + " { spawn \"${bind.command}\"; }")
      cfg.keybinds);
in
{
  # options.dot.desktopEnvironment = {
  #   sessionVariables = lib.mkOption {
  #     type = with lib.types; lazyAttrsOf (oneOf [ str path int float ]);
  #     default = { };
  #     example = { EDITOR = "hx"; };
  #     description = ''
  #       Environment variables to set on session start with Niri.
  #     '';
  #   };

  #   sessionStartup = lib.mkOption {
  #     type = with lib.types; listOf str;
  #     default = [ ];
  #     example = [ "keepassxc" ];
  #     description = ''
  #       Commands to execute on session start with Niri.
  #     '';
  #   };

  #   keybinds = lib.mkOption {
  #     # TODO: strictly check for the mods, key and command options 
  #     type = with lib.types; listOf (lazyAttrsOf (oneOf [ str (listOf str) ]));
  #     default = [ ];
  #     example = [
  #       {
  #         mods = [ "super" ];
  #         key = "w";
  #         command = "firefox";
  #       }
  #     ];
  #     description = ''
  #       Keybinds to set with Niri.
  #     '';
  #   };
  # };

  config = {
    # shared = {
    #   dot = {
    #     desktopEnvironment.startup = "${pkgs.niri}/bin/niri";
    #   };
    # };

    home.shared = {
      home.sessionVariables = cfg.sessionVariables;
      systemd.user.sessionVariables = cfg.sessionVariables;

      home.packages = [
        pkgs.niri
        switch-layout
        current-layout
      ];

      xdg.configFile."niri/config.kdl".text = ''
        screenshot-path "${config.xdg.userDirs.pictures}/screenshots"

        output "${config.dot.mainMonitor}" {
          variable-refresh-rate
        }
  
        ${builtins.readFile ./config.kdl}
        
        cursor {
          xcursor-theme "${config.dot.cursor-theme.name}"
          xcursor-size ${builtins.toString config.dot.cursor-theme.size}
        }

        environment {
          ${vars}
        }

        ${startup}

        binds {
          Mod+Space { spawn "${switch-layout}/bin/switch-layout"; }

          ${builtins.readFile ./binds.kdl}

          ${binds}
        }
      '';
    };
  };
}

