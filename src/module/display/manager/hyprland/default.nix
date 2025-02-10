{ pkgs, lib, config, ... }:

# FIXME: https://github.com/NVIDIA/egl-wayland/issues/126#issuecomment-2594012291

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

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  hasNvidia = config.dot.hardware.graphics.driver == "nvidia";

  floatingSizeString = builtins.toString (config.dot.hardware.monitor.height / 2);
in
{
  config = lib.mkIf (hasMonitor && hasWayland) {
    desktopEnvironment.startup = "${pkgs.hyprland}/bin/Hyprland";
    desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "c";
        command = "${pkgs.hyprpicker}/bin/hyprpicker --no-fancy | ${pkgs.wl-clipboard}/bin/wl-copy";
      }
    ];
  };

  system = lib.mkIf (hasMonitor && hasWayland) {
    programs.hyprland.enable = true;
    programs.hyprland.xwayland.enable = true;
    programs.hyprland.systemd.setPath.enable = true;

    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" =
      lib.mkIf hasNvidia {
        source = ./50-limit-free-buffer-pool-in-wayland-compositors.json;
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

      windowrulev2=size ${floatingSizeString} ${floatingSizeString},floating:1

      ${vars}

      ${startup}

      ${binds}

      ${windowrules}
    '';
  };
}

