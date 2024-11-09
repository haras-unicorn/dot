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

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  shared = lib.mkIf (hasMonitor && hasWayland) {
    dot = {
      desktopEnvironment.startup = "${pkgs.dbus}/bin/dbus-run-session ${pkgs.hyprland}/bin/Hyprland";
      desktopEnvironment.keybinds = [
        {
          mods = [ "super" ];
          key = "c";
          command = "${pkgs.hyprpicker}/bin/hyprpicker";
        }
      ];
    };
  };

  home = lib.mkIf (hasMonitor && hasWayland) {
    home.sessionVariables = cfg.sessionVariables;
    systemd.user.sessionVariables = cfg.sessionVariables;

    home.packages = [
      switch-layout
      current-layout
      pkgs.hyprcursor
      pkgs.hyprpicker
    ];

    wayland.windowManager.hyprland.enable = true;
    wayland.windowManager.hyprland.xwayland.enable = true;
    wayland.windowManager.hyprland.systemd.enable = true;
    wayland.windowManager.hyprland.extraConfig = ''
      monitor = , preferred, auto, 1
      monitor = ${config.dot.hardware.monitor.main}, highrr, auto, 1
  
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
}

