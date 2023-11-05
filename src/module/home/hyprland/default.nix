{ pkgs, config, ... }:

# TODO: window rules into modules

with pkgs.lib;
let
  cfg = config.de;

  layout = pkgs.writeShellApplication {
    name = "layout";
    runtimeInputs = [ pkgs.hyprland ];
    text = ''
      hyprctl devices | \
        grep -Pzo "Keyboard at.*\n.*\n" | \
        grep -Pva "Keyboard at" | \
        grep -Pva "power" | \
        xargs -IR hyprctl switchxkblayout R next
    '';
  };

  vars = builtins.foldl'
    (vars: next: "${vars}\n${next}")
    ""
    (builtins.map
      (name: "env = ${name}, ${builtins.toString cfg.sessionVariables."${name}"}")
      (builtins.attrNames cfg.sessionVariables));

  startup = builtins.foldl'
    (vars: next: "${vars}\n${next}")
    ""
    (builtins.map
      (command: "exec-once = ${builtins.toString command}")
      cfg.sessionStartup);
in
{
  options.de =
    {
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
    };
  config =
    {
      home.packages = [ layout ];

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
      '';

      programs.lulezojne.config.plop = [
        {
          template = builtins.readFile ./colors.conf;
          "in" = "${config.xdg.configHome}/hypr/colors.conf";
        }
      ];
    };
}

