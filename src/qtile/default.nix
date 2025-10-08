{
  pkgs,
  lib,
  config,
  ...
}:

# FIXME: links not opening https://github.com/flatpak/xdg-desktop-portal-gtk/issues/440
# WORKAROUND: these commands on de startup
# systemctl --user import-environment PATH
# systemctl --user restart xdg-desktop-portal.service

let
  cfg = config.dot.desktopEnvironment;

  colors = config.lib.stylix.colors.withHashtag;
  fonts = config.stylix.fonts;

  package = pkgs.qtile-unwrapped;

  current-layout = pkgs.writeShellApplication {
    name = "current-layout";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .active_keymap' | \
      #   head -n 1
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
      # hyprctl devices -j | \
      #   jq -r '.keyboards[] | select(.name | contains("power") | not) | .name' | \
      #   xargs -IR sh -c 'hyprctl switchxkblayout R next &>/dev/null'

      ${current-layout}/bin/current-layout
    '';
  };

  startup = ''
    @hook.subscribe.startup_once
    def startup_once():
        lazy.spawn("systemctl --user import-environment PATH")
        lazy.spawn("systemctl --user restart xdg-desktop-portal.service")
  ''
  + (lib.strings.concatStringsSep "\n" (
    builtins.map (command: "    lazy.spawn(\"${builtins.toString command}\")") cfg.sessionStartup
  ));

  vars = lib.strings.concatStringsSep "\n" (
    builtins.map (name: ''
      os.environ["${name}"] = "${builtins.toString cfg.sessionVariables."${name}"}"
    '') (builtins.attrNames cfg.sessionVariables)
  );

  binds = lib.strings.concatStringsSep "\n" (
    builtins.map (
      bind:
      let
        mods = builtins.map (
          mod:
          if mod == "super" then
            "mod4"
          else if mod == "alt" then
            "mod1"
          else if mod == "ctrl" then
            "control"
          else
            mod
        ) bind.mods;

        modString =
          if (builtins.length mods) == 0 then "" else ''"${lib.strings.concatStringsSep ''", "'' mods}"'';
      in
      ''
        keys.append(
            Key(
                [${modString}],
                "${bind.key}",
                lazy.spawn("${bind.command}")
            )
        )
      ''
    ) cfg.keybinds
  );

  windowrules = lib.strings.concatStringsSep "\n" (
    builtins.map (
      windowrule:
      let
        rule = if windowrule.rule == "float" then "float" else builtins.throw "Unknown window rule";
        selector = if windowrule.selector == "class" then "wm_class" else builtins.throw "Unknown selector";
        arg = windowrule.arg;
      in
      "floating_layout.${rule}_rules.append(Match(${selector}=\"${arg}\"))"
    ) cfg.windowrules
  );

  hasMonitor = config.dot.hardware.monitor.enable;
  hasWayland = config.dot.hardware.graphics.wayland;
in
{
  branch.nixosModule.nixosModule = lib.mkIf (hasMonitor && !hasWayland) {
    dot.desktopEnvironment.startup = "qtile";

    services.xserver.windowManager.qtile.enable = true;
    services.xserver.windowManager.qtile.package = package;
    services.xserver.windowManager.qtile.extraPackages =
      python3Packages: with python3Packages; [
        psutil
      ];
  };

  branch.homeManagerModule.homeManagerModule = lib.mkIf (hasMonitor && !hasWayland) {
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
        "background": "${colors.base00}",
        "text": "${colors.base08}",
        "danger": "${colors.red}",
        "danger-alternate": "${colors.brown}",
        "primary": "${colors.base09}",
        "accent": "${colors.base10}"
      }

      ${builtins.readFile ./config.py}

      widget_defaults["font"] = "${fonts.sansSerif.name}"
      widget_defaults["fontsize"] = ${builtins.toString fonts.sizes.desktop}
      widget_defaults["icon_size"] = ${builtins.toString fonts.sizes.desktop}

      keys.append(
          Key(
              ["mod4"],
              "space",
              lazy.spawn("${switch-layout}/bin/switch-layout")
          )
      )

      ${startup}

      ${vars}

      ${binds}

      ${windowrules}
    '';

    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
    };
  };
}
