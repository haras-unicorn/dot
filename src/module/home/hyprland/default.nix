{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.de;

  switch-layout = pkgs.writeShellApplication {
    name = "switch-layout";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl devices | \
        grep -Pzo "Keyboard at.*\n.*\n" | \
        grep -Pva "Keyboard at" | \
        grep -Pva "power" | \
        xargs -IR hyprctl switchxkblayout R next
    '';
  };

  reload-de = pkgs.writeShellApplication {
    name = "reload-de";
    runtimeInputs = [ pkgs.qtile ];
    text = ''
      qtile cmd-obj -o cmd -f restart
    '';
  };

  vars = strings.concatStringsSep
    "\n"
    (builtins.map
      (name: "env = ${name}, ${builtins.toString cfg.sessionVariables."${name}"}")
      (builtins.attrNames cfg.sessionVariables));

  startup = strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "exec-once = ${builtins.toString command}")
      cfg.sessionStartup);

  binds = strings.concatStringsSep
    "\n"
    (builtins.map
      (bind: "bind = ${strings.concatStringsSep " " bind.mods}, ${bind.key}, exec, ${bind.command}")
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
    programs.lulezojne.config.plop = [
      {
        template = builtins.readFile ./colors.conf;
        "in" = "${config.xdg.configHome}/hypr/colors.conf";
      }
    ];

    home.sessionVariables = cfg.sessionVariables;
    systemd.user.sessionVariables = cfg.sessionVariables;

    home.packages = [ switch-layout reload-de ];

    wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland.enableNvidiaPatches = true;
    wayland.windowManager.hyprland.xwayland.enable = true;
    wayland.windowManager.hyprland.extraConfig = ''
      monitor = , preferred, auto, 1
      monitor = ${config.dot.hardware.mainMonitor}, highrr, auto, 1
  
      ${builtins.readFile ./hyprland.conf}

      source = ${config.xdg.configHome}/hypr/colors.conf

      bind = super, Space, exec, ${layout}/bin/layout

      env = XDG_CURRENT_DESKTOP, Hyprland
      env = XDG_SESSION_DESKTOP, Hyprland

      ${vars}

      ${startup}

      ${binds}
    '';
  };
}

