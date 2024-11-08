{ pkgs, lib, config, ... }:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# WORKAROUND: these commands on de startup
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service

let
  cfg = config.dot.desktopEnvironment;

  current-layout = pkgs.writeShellApplication {
    name = "current-layout";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      hyprctl devices -j | \
        jq -r '.keyboards[] | select(.name | contains("power") | not) | .active_keymap' | \
        head -n 1
    '';
  };

  switch-layout = pkgs.writeShellApplication {
    name = "switch-layout";
    runtimeInputs = [ pkgs.hyprland pkgs.jq ];
    text = ''
      hyprctl devices -j | \
        jq -r '.keyboards[] | select(.name | contains("power") | not) | .name' | \
        xargs -IR sh -c 'hyprctl switchxkblayout R next &>/dev/null'

      ${current-layout}/bin/current-layout
    '';
  };

  vars = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (name: "env = ${name}, ${builtins.toString cfg.sessionVariables."${name}"}")
      (builtins.attrNames cfg.sessionVariables));

  startup = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (command: "exec-once = ${builtins.toString command}")
      cfg.sessionStartup);

  binds = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (bind: "bind = ${lib.strings.concatStringsSep " " bind.mods}, ${bind.key}, exec, ${bind.command}")
      cfg.keybinds);

  windowrules = lib.strings.concatStringsSep
    "\n"
    (builtins.map
      (windowrule: "windowrulev2 ="
        + " ${windowrule.rule}"
        + ", ${windowrule.selector}:(${windowrule.arg})")
      cfg.windowrules);

  bootstrap = config.dot.colors.bootstrap;
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
          xselector = "wm_class";
          arg = "org.keepassxc.KeePassXC";
          xarg = "keepassxc";
        }
      ];
    };
  };

  config = {
    shared = {
      dot = {
        desktopEnvironment.startup = "${pkgs.hyprland}/bin/Hyprland";
      };
    };

    system = {
      programs.hyprland.enable = true;
      programs.hyprland.xwayland.enable = true;
    };

    home.shared = {
      home.sessionVariables = cfg.sessionVariables;
      systemd.user.sessionVariables = cfg.sessionVariables;

      home.packages = [
        switch-layout
        current-layout
        pkgs.hyprcursor
      ];

      wayland.windowManager.hyprland.enable = true;
      wayland.windowManager.hyprland.xwayland.enable = true;
      wayland.windowManager.hyprland.extraConfig = ''
        monitor = , preferred, auto, 1
        monitor = ${config.dot.mainMonitor}, highrr, auto, 1
  
        ${builtins.readFile ./hyprland.conf}

        bind = super, space, exec, ${switch-layout}/bin/switch-layout

        env = XDG_CURRENT_DESKTOP, Hyprland
        env = XDG_SESSION_DESKTOP, Hyprland

        env = HYPRCURSOR_THEME,${config.dot.cursor-theme.name}
        env = HYPRCURSOR_SIZE,${builtins.toString config.dot.cursor-theme.size}

        env = XCURSOR_THEME,${config.dot.cursor-theme.name}
        env = XCURSOR_SIZE,${builtins.toString config.dot.cursor-theme.size}

        exec-once = ${pkgs.systemd}/bin/systemctl --user import-environment PATH
        exec-once = ${pkgs.systemd}/bin/systemctl --user restart xdg-desktop-portal.service

        general {
          col.active_border = ${bootstrap.primary.normal.hypr} ${bootstrap.accent.normal.hypr}
          col.inactive_border = ${bootstrap.secondary.normal.hypr}
        }

        ${vars}

        ${startup}

        ${binds}

        ${windowrules}
      '';
    };
  };
}

