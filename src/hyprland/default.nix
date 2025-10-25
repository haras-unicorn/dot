{
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: https://github.com/NVIDIA/egl-wayland/issues/126#issuecomment-2594012291

let
  cfg = config.dot.desktopEnvironment;

  current-layout = pkgs.writeShellApplication {
    name = "current-layout";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      hyprctl devices -j | \
        jq -r '.keyboards[] | select(.name | contains("power") | not) | .active_keymap' | \
        head -n 1
    '';
  };

  switch-layout = pkgs.writeShellApplication {
    name = "switch-layout";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      hyprctl devices -j | \
        jq -r '.keyboards[] | select(.name | contains("power") | not) | .name' | \
        xargs -IR sh -c 'hyprctl switchxkblayout R next &>/dev/null'

      ${current-layout}/bin/current-layout
    '';
  };

  vars = lib.strings.concatStringsSep "\n" (
    builtins.map (name: "env = ${name}, ${builtins.toString cfg.sessionVariables."${name}"}") (
      builtins.attrNames cfg.sessionVariables
    )
  );

  startup = lib.strings.concatStringsSep "\n" (
    builtins.map (command: "exec-once = ${builtins.toString command}") cfg.sessionStartup
  );

  binds = lib.strings.concatStringsSep "\n" (
    builtins.map (
      bind: "bind = ${lib.strings.concatStringsSep " " bind.mods}, ${bind.key}, exec, ${bind.command}"
    ) cfg.keybinds
  );

  windowrules = lib.strings.concatStringsSep "\n" (
    builtins.map (
      windowrule:
      let
        rule =
          if windowrule.rule == "float" then
            "float"
          else if windowrule.rule == "hide" then
            "size 0 0"
          else
            builtins.throw "Unknown window rule";
      in
      "windowrulev2 =" + " ${rule}" + ", ${windowrule.selector}:(${windowrule.arg})"
    ) cfg.windowrules
  );

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;

  hasNvidia = config.dot.hardware.graphics.driver == "nvidia";

  floatingSizeString = builtins.toString (config.dot.hardware.monitor.height / 2);

  fullscreenCheck = pkgs.writeShellApplication {
    name = "hyprland-fullscreen-check";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      hyprctl -j activewindow 2>/dev/null \
        | jq -e '.fullscreen > 0' >/dev/null
    '';
  };
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && hasWayland) {
    dot.desktopEnvironment.startup = [
      {
        name = "Hyprland";
        command = "${pkgs.hyprland}/bin/Hyprland";
      }
    ];

    programs.hyprland.enable = true;
    programs.hyprland.xwayland.enable = true;
    programs.hyprland.systemd.setPath.enable = true;

    environment.etc."nvidia/nvidia-application-profiles-rc.d/550-limit-free-buffer-pool-in-hyprland.json.json" =
      lib.mkIf hasNvidia {
        source = ./50-limit-free-buffer-pool-in-hyprland.json;
      };
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && hasWayland) {
    dot.desktopEnvironment.fullscreenChecks = {
      Hyprland = fullscreenCheck;
    };

    dot.desktopEnvironment.keybinds = [
      {
        mods = [ "super" ];
        key = "c";
        command = "${pkgs.hyprpicker}/bin/hyprpicker --no-fancy | ${pkgs.wl-clipboard}/bin/wl-copy";
      }
    ];

    home.sessionVariables = cfg.sessionVariables;
    systemd.user.sessionVariables = cfg.sessionVariables;

    home.packages = [
      switch-layout
      current-layout
      pkgs.hyprcursor
      pkgs.hyprpicker
    ];

    xdg.portal.extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
    ];
    xdg.portal.config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };

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

      windowrulev2=size ${floatingSizeString} ${floatingSizeString},floating:1,,class:negative:^.*steam.*$

      ${vars}

      ${startup}

      ${binds}

      ${windowrules}
    '';
  };
}
