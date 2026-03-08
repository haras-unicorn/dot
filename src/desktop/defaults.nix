{ ... }:

{
  flake.nixosModules.desktop-defaults =
    { config, ... }:
    let
      user = config.dot.host.user;
    in
    {
      # NOTE: this is a clusterfuck anyway
      systemd.user.extraConfig = ''
        DefaultEnvironment="PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      '';

      users.users.${user}.extraGroups = [
        "video"
      ];
    };

  flake.homeModules.desktop-defaults =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      terminal = "${config.dot.terminal.package}/bin/${config.dot.terminal.bin}";
      shell = "${config.dot.shell.package}/bin/${config.dot.shell.bin}";
      browser = "${config.dot.browser.package}/bin/${config.dot.browser.bin}";
      visual = "${config.dot.visual.package}/bin/${config.dot.visual.bin}";
      editor = "${config.dot.editor.package}/bin/${config.dot.editor.bin}";

      browserDesktop = "${config.dot.browser.package}/share/applications/${config.dot.browser.bin}.desktop";
      browserMime = {
        "text/html" = browserDesktop;
        "x-scheme-handler/http" = browserDesktop;
        "x-scheme-handler/https" = browserDesktop;
      };

      visualDesktop = "${config.dot.visual.package}/share/applications/${config.dot.visual.bin}.desktop";
      visualMime = {
        "text/css" = visualDesktop;
        "application/javascript" = visualDesktop;
        "application/json" = visualDesktop;
        "application/x-sh" = visualDesktop;
        "application/xhtml+xml" = visualDesktop;
        "application/xml" = visualDesktop;
      };

      hasMonitor = config.dot.hardware.monitor.enable;
      hasMouse = config.dot.hardware.mouse.enable;
      hasKeyboard = config.dot.hardware.keyboard.enable;

      copy = pkgs.writeShellApplication {
        name = "copy";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          mkdir -p '${config.xdg.dataHome}'
          cat > '${config.xdg.dataHome}/clipboard'
        '';
      };

      paste = pkgs.writeShellApplication {
        name = "paste";
        runtimeInputs = [
          pkgs.coreutils
        ];
        text = ''
          if [ -f '${config.xdg.dataHome}/clipboard' ]; then
            cat '${config.xdg.dataHome}/clipboard'
          fi
        '';
      };

      type = pkgs.writeShellApplication {
        name = "type";
        runtimeInputs = [
          pkgs.coreutils
          paste
        ];
        text = ''
          paste
        '';
      };

      type-clipboard = pkgs.writeShellApplication {
        name = "type-clipboard";
        runtimeInputs = [
          pkgs.coreutils
          config.dot.shell.paste
          config.dot.shell.type
        ];
        text = ''
          type "$(paste)"
        '';
      };

      mkScreenshot =
        { name, ... }:
        pkgs.writeShellApplication {
          name = "screenshot";
          runtimeInputs = [
            pkgs.fbcat
            config.dot.shell.copy
            pkgs.coreutils
          ];
          text = ''
            tmp="$(mktemp -d)"
            mkdir -p "$tmp"
            trap 'rm -rf "$tmp"' EXIT

            name="$(date -Iseconds)"
            type="png"
            fbgrab "$tmp/$name.$type"
            copy -t image/$type < "$tmp/$name.$type"

            dir='${config.xdg.userDirs.pictures}/screenshots'
            mkdir -p "$dir"
            mv -f "$tmp/$name.$type" "$dir/$name.$type"
          '';
        };

      screenshot = mkScreenshot { name = "screenshot"; };
      regionshot = mkScreenshot { name = "regionshot"; };

      mime = lib.mkMerge [
        (lib.mkIf (hasMonitor) browserMime)
        (lib.mkIf (hasKeyboard && hasMonitor) visualMime)
      ];
    in
    {
      dot.shell = lib.mkDefault {
        inherit
          copy
          paste
          type
          screenshot
          regionshot
          ;
      };

      dot.desktopEnvironment.keybinds = lib.mkMerge [
        (lib.mkIf hasMonitor [
          {
            mods = [ "super" ];
            key = "w";
            command = "${browser}";
          }
        ])
        (lib.mkIf (hasMonitor && hasKeyboard) [
          {
            mods = [ "super" ];
            key = "t";
            command = "${terminal} ${shell}";
          }
          {
            mods = [ "super" ];
            key = "Print";
            command = "${config.dot.shell.screenshot}/bin/screenshot";
          }
        ])
        (lib.mkIf (hasMonitor && hasKeyboard && hasMouse) [
          {
            mods = [
              "super"
              "shift"
            ];
            key = "Print";
            command = "${config.dot.shell.regionshot}/bin/regionshot";
          }
        ])
        (lib.mkIf (hasMonitor && hasKeyboard) [
          {
            mods = [
              "ctrl"
              "alt"
            ];
            key = "v";
            command = "${type-clipboard}/bin/type-clipboard";
          }
        ])
      ];

      home.packages = [
        pkgs.xdg-user-dirs
        pkgs.xdg-utils
        pkgs.shared-mime-info

        config.dot.shell.copy
        config.dot.shell.paste
        config.dot.shell.screenshot
        config.dot.shell.regionshot
      ];

      home.sessionVariables = lib.mkMerge [
        (lib.mkIf hasMonitor {
          BROWSER = "${browser}";
          VISUAL = "${visual}";
        })
        {
          EDITOR = "${editor}";
        }
      ];

      xdg.mime.enable = true;
      xdg.mimeApps.enable = true;
      xdg.mimeApps.associations.added = mime;
      xdg.mimeApps.defaultApplications = mime;

      xdg.enable = true;
      xdg.userDirs.enable = true;
      xdg.userDirs.createDirectories = true;
      xdg.userDirs.desktop = "${config.home.homeDirectory}/desktop";
      xdg.userDirs.download = "${config.home.homeDirectory}/download";
      xdg.userDirs.music = "${config.home.homeDirectory}/music";
      xdg.userDirs.pictures = "${config.home.homeDirectory}/pictures";
      xdg.userDirs.videos = "${config.home.homeDirectory}/videos";
      xdg.userDirs.templates = "${config.home.homeDirectory}/templates";
      xdg.userDirs.documents = "${config.home.homeDirectory}/documents";
      xdg.userDirs.publicShare = "${config.home.homeDirectory}/public";
    };
}
